module CloudComputing
  class Position < ApplicationRecord
    # cloud_computing_positions
    belongs_to :item, inverse_of: :positions
    belongs_to :holder, polymorphic: true, autosave: true, inverse_of: :positions
    # belongs_to :request, -> { where(cloud_computing_positions: { holder_type: 'Request' }) },
    #                    foreign_key: 'holder_id'
    belongs_to :request, -> { where("#{Position.table_name}": { holder_type: Request.to_s }) },
                              foreign_key: 'holder_id'

    belongs_to :access, -> { where("#{Position.table_name}": { holder_type: Access.to_s }) },
                              foreign_key: 'holder_id'


    # validates :item_id, uniqueness: { scope: %i[holder_id holder_type] }
    has_many :from_links, class_name: 'CloudComputing::PositionLink', inverse_of: :from, dependent: :destroy, foreign_key: :from_id
    has_many :to_links, class_name: 'CloudComputing::PositionLink', inverse_of: :to, dependent: :destroy, foreign_key: :to_id

    # has_many :to_positions, class_name: Position.to_s, through: :from_links, source: :to
    accepts_nested_attributes_for :from_links, allow_destroy: true

    scope :with_user_requests, (lambda do |user|
      joins(:request).where(cloud_computing_requests: {
                              status: 'created', created_by_id: user
                            })
    end)

    def to_item_kinds
      puts ItemKind.joins(:to_conditions)
          .where(cloud_computing_conditions: { from_id: item.item_kind.self_and_ancestors,
                                               from_type: ItemKind.to_s }).map(&:name).inspect.red

      ItemKind.joins(:to_conditions)
          .where(cloud_computing_conditions: { from_id: item.item_kind.self_and_ancestors,
                                               from_type: ItemKind.to_s })
      # item.item_kind.self_and_ancestors.includes()
    end

    def to_item_kinds_hash
      to_item_kinds.map { |i_k| { id: i_k.id, text: i_k.name } }
    end

    def as_json(_options = {})
      {
        id: id,
        item_name: item.name,
        amount: amount,
        to_item_kinds: to_item_kinds_hash
      }
    end





    # scope :with_user_requests, lambda do |user|
    #   # select('*, positions from (amount)')
    #   joins(positions: :requests).where(cloud_computing_requests: {
    #                                       status: 'created', created_by: user
    #                                     }).uniq
    #
    # end # joins(positions: :requests)
        #                                  .where(cloud_computing_requests: { status: 'created', created_by: user })}
    # scope :joins_requests, -> { joins('INNER JOIN cloud_computing_requests AS c_r ON c_r.id = cloud_computing_positions.holder_id AND
    #    cloud_computing_positions.holder_type=\'CloudComputing::Request\' ') }

    validates :item, :holder, presence: true

    validate do
      if item&.max_count && amount.present? && amount > item.max_count
        errors.add :amount, 'error'
      end
    end

    def name
      item.name
    end

  end

end
