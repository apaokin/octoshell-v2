namespace :support do
  task :create_bot, [:pass] => :environment  do |_t, args|
    Support::Notificator.new.create_bot(args[:pass])
  end

  task update_1: :environment do
    ActiveRecord::Base.transaction do
      Support::TopicsField.includes(:field).each do |t_f|
        t_f.required = t_f.field.required
        t_f.save!
      end
      Support::FieldValue.where(value: ['', nil]).destroy_all
      Support::FieldValue.all.each do |field_value|
        puts field_value.id.inspect.green
        next unless field_value.field_id

        field = Support::Field.find(field_value.field_id)
        next unless field

        topics_field = field.topics_fields.find_by(topic: field_value.ticket.topic)
        next unless topics_field

        field_value.topics_field = topics_field
        field_value.save!
      end
    end
  end

  task update_2: :environment do
    ActiveRecord::Base.transaction do
      Support::Topic.group(:id).left_joins(:subtopics)
                             .having('count(subtopics_support_topics.id) > 0')
                             .to_a.map do |topic|

        topics_fields = topic.topics_fields
        topics_fields.each do |topics_field|
          raise "not leaf topic #{topic} has field_value" if topics_field.field_values.any?
          topics_field.destroy!
        end
      end

      project = Support::Field.create(name_ru: 'Проект', name_en: 'Project',
                                      kind: 'model_collection',
                                      model_collection: 'project')


      table = Roo::Spreadsheet.open('fields.xlsx')
      rows = table.sheet(0).to_a
      rows.delete_at(0)
      rows.each do |row|
        field = Support::Field.find row[0]
        type = row[5]
        field.kind = type
        field.save!
        if field.model_collection?
          field.model_collection = 'cluster'
        elsif field.check_box?
          field.field_options.create!(name_ru: 'Да', name_en: 'Yes')
        elsif field.radio?
          field.field_options.create!(name_ru: 'Да', name_en: 'Yes')
          field.field_options.create!(name_ru: 'Нет', name_en: 'No')
        end
        field.save!
      end

      cluster = Support::Field.find(14)
      cluster.name_ru = 'Кластер'
      cluster.name_en = 'Cluster'
      cluster.save!

      Support::Topic.leaf_topics.each do |topic|
        cluster_fields_present = topic.topics_fields.where(field_id: [14, 6]).any?
        unless cluster_fields_present
          topic.topics_fields.create!(field: cluster, required: false)
        end
        topic.topics_fields.create!(field: project, required: false)
      end

      Support::Ticket.all.includes(:topic, :field_values).each do |ticket|
        puts ticket.id.to_s.green
        topic = ticket.topic
        if ticket.cluster_id.present?
          cluster_topics_field = topic.topics_fields
                                      .where(field_id: [6, cluster.id]).first

          cluster_values = ticket.field_values.to_a.select do |field_value|
            [14, 6].include? field_value.field_id
          end
          first = cluster_values.first
          if first
            first.value = ticket.cluster_id
            first.save!
          else
            raise "cluster_topics_field for #{ticket} is empty" unless cluster_topics_field
            ticket.field_values.create!(value: ticket.cluster_id,
                                        topics_field: cluster_topics_field)
          end
        end
        if ticket.project_id.present?
          project_topics_field = topic.topics_fields.find_by!(field_id: project.id)
          ticket.field_values.create!(value: ticket.project_id,
                                      topics_field: project_topics_field)
        end

      end




    end
  end

  task fix_topics: :environment do

    def merge(source, to)
      return if source == to

      raise 'merge error' if source.subtopics.any?

      Support::Ticket.where(topic: source).update_all(topic_id: to.id)
      source.destroy!
    end

    ActiveRecord::Base.transaction do
      parent_topic = Support::Notificator.new.parent_topic
      core_topic = Core::Notificator.new.topic
      pack_topic = Pack::Notificator.new.topic

      Support::Topic.where(name_ru: core_topic.name_ru).each do |t|
        merge(t, core_topic)
      end

      Support::Topic.where(name_ru: pack_topic.name_ru).each do |t|
        merge(t, pack_topic)
      end

      Support::Topic.where(name_ru: 'Заявка на доступ к версиям пакетов').each do |t|
        merge(t, Pack.support_access_topic)
      end

      Support::Topic.where(name_ru: parent_topic.name_ru).each do |t|
        merge(t, parent_topic)
      end

      parent_topic.update!(visible_on_create: false)
    end
  end
end
