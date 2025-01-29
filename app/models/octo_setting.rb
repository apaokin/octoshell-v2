class OctoSetting < ApplicationRecord
  KINDS = %i[policy full_organization_name creator].freeze
  translates :value
  validates :value_ru, :value_en, :kind, presence: true
  after_commit do
    if active
      OctoSetting.where(kind: kind, active: true).where.not(id: id).each do |o|
        o.update!(active: false)
      end
    end
  end
  def self.human_kinds
    KINDS.map do |kind|
      [kind, human_attribute_name(kind)]
    end
  end

  def self.human_value_by_kind(kind)
    raise "wrong #{kind} kind" unless KINDS.include? kind.to_sym

    where(kind: kind, active: true).first&.value&.html_safe || 'not_set'
  end

  def human_value(column)
    public_send(column).html_safe
  end

end
