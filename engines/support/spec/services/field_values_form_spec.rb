require 'main_spec_helper'
module Support
  class TestModel < ApplicationRecord

  end


  RSpec.describe FieldValuesForm do
    before(:each) do
      @topic = create(:topic)
      ActiveRecord::Base.connection.create_table :support_test_models do |t|
        t.string :title
        t.text :body
      end
      Support::Interface.ticket_field(key: :test_key,
                                      human: :title,
                                      user_query: proc { TestModel.all })
      4.times do |i|
        TestModel.create!(title: "title_#{i}", body: 'body')
      end

      @p_ticket = create(:ticket, topic: @topic)
      @topic.fields.create!("name_#{I18n.locale}": 'model_collection',
                            kind: 'model_collection',
                            model_collection: 'test_key')
      @model_topics_field = TopicsField.last
      @p_ticket.field_values.create!(topics_field: @model_topics_field,
                                     value: TestModel.first.id.to_s)
      @topic.fields.create!("name_#{I18n.locale}": 'text',
                            kind: 'text')
      @text_topics_field = TopicsField.last
      @p_ticket.field_values.create!(topics_field: @text_topics_field,
                                     value: 'text_value')



      %w[radio check_box].each do |type|
        cur_field = @topic.fields.create!("name_#{I18n.locale}": type,
                                          kind: type)
        3.times do |i|
          cur_field.field_options.create!("name_#{I18n.locale}": "#{type}_#{i}")
        end
        @p_ticket.field_values.create!(topics_field: TopicsField.last,
                                       value: cur_field.field_options.first.id.to_s)

      end


    end


    it 'creates ticket' do
      hash = {}
      hash[@model_topics_field.field_id.to_s] = TestModel.first.id.to_s
      hash[@text_topics_field.field_id.to_s] = 'text_value'
      cur_field = Field.find_by_kind('radio')
      hash[cur_field.id.to_s] = cur_field.field_options.first.id
      cur_field = Field.find_by_kind('check_box')
      hash[cur_field.id.to_s] = cur_field.field_options.take(2).map(&:id)


      @ticket = build(:ticket, topic: @topic)
      expect(FieldValuesForm.new(@ticket, hash).valid?).to eq true
      expect(@ticket.valid?).to eq true
      @ticket.save!
      expect(@ticket.field_values.first).to(
        have_attributes(topics_field: @model_topics_field,
                        value: TestModel.first.id.to_s))
      expect(@ticket.field_values.second).to(
        have_attributes(topics_field: @text_topics_field,
                        value: 'text_value'))
      radio_tf = topics_field_by_kind_and_topic(@topic, 'radio')
      check_tf = topics_field_by_kind_and_topic(@topic, 'check_box')

      expect(@ticket.field_values.where(topics_field: radio_tf,
                                        value: radio_tf.field.field_options.first.id.to_s).first).to be_truthy

      expect(@ticket.field_values.where(topics_field: check_tf,
                                        value: check_tf.field.field_options.first.id.to_s).first).to be_truthy

      expect(@ticket.field_values.where(topics_field: check_tf,
                                        value: check_tf.field.field_options.second.id.to_s).first).to be_truthy
    end


    it 'creates ticket with 0 field_values' do
      hash = {}
      hash[@model_topics_field.field_id.to_s] = ''
      hash[@text_topics_field.field_id.to_s] = ''
      cur_field = Field.find_by_kind('radio')
      hash[cur_field.id.to_s] = ''
      cur_field = Field.find_by_kind('check_box')
      hash[cur_field.id.to_s] = ['']


      @ticket = build(:ticket, topic: @topic)
      expect(FieldValuesForm.new(@ticket, hash).valid?).to eq true
      expect(@ticket.valid?).to eq true
      puts @ticket.field_values.inspect.green
      @ticket.save!
      expect(@ticket.field_values.count).to eq 0
    end

    it 'updates ticket with 0 field values' do
      hash = {}
      hash[@model_topics_field.field_id.to_s] = ''
      hash[@text_topics_field.field_id.to_s] = ''
      cur_field = Field.find_by_kind('radio')
      hash[cur_field.id.to_s] = ''
      cur_field = Field.find_by_kind('check_box')
      hash[cur_field.id.to_s] = []

      expect(FieldValuesForm.new(@p_ticket, hash).valid?).to eq true
      expect(@p_ticket.valid?).to eq true
      @p_ticket.save!
      expect(@p_ticket.field_values.count).to eq 0
    end


    it 'updates ticket' do
      hash = {}
      hash[@model_topics_field.field_id.to_s] = TestModel.last.id.to_s
      hash[@text_topics_field.field_id.to_s] = 'updated_text'
      cur_field = Field.find_by_kind('radio')
      hash[cur_field.id.to_s] = cur_field.field_options.second.id
      cur_field = Field.find_by_kind('check_box')
      hash[cur_field.id.to_s] = cur_field.field_options.order('id DESC').take(1).map(&:id)

      last_id = FieldValue.last.id
      expect(FieldValuesForm.new(@p_ticket, hash).valid?).to eq true
      expect(@p_ticket.valid?).to eq true
      @p_ticket.save!

      new_last_id = FieldValue.last.id
      expect(new_last_id).to eq(last_id + 1)

      expect(@p_ticket.field_values.first).to(
        have_attributes(topics_field: @model_topics_field,
                        value: TestModel.last.id.to_s))
      expect(@p_ticket.field_values.second).to(
        have_attributes(topics_field: @text_topics_field,
                        value: 'updated_text'))
      radio_tf = topics_field_by_kind_and_topic(@topic, 'radio')
      check_tf = topics_field_by_kind_and_topic(@topic, 'check_box')
      expect(@p_ticket.field_values.where(topics_field: radio_tf,
                                        value: radio_tf.field.field_options.second.id.to_s).first).to be_truthy

      expect(@p_ticket.field_values.where(topics_field: check_tf,
                                        value: check_tf.field.field_options.last.id.to_s).first).to be_truthy
    end






  end
end
