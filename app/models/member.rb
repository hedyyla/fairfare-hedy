class Member < ApplicationRecord
  has_one :user, dependent: :destroy
  has_many :split_members, dependent: :destroy
  has_many :splits, through: :split_members
  has_many :payers
  has_many :item_members
  has_many :items, through: :item_members

  validates :phone_number, presence: true, uniqueness: true

  def registered?
    !user.nil?
  end

  def given_nickname(by_user)
    return by_user.username if by_user.member == self

    contact = Contact.find_by(
      member: self,
      user: by_user
    )
    contact&.nickname
  end

  def payer?(bill)
    payer = Payer.find_by(
      member: self,
      bill:
    )
    return payer ? true : false
    # code method to find out if member has payer for bill
    # contact ? contact.nickname : 'No nickname'
  end

  def payer_id(bill)
    payer = Payer.find_by(
      member: self,
      bill:
    )
    return payer.id
  end

  def payer(bill)
    payer = Payer.find_by(
      member: self,
      bill:
    )
    return payer
  end

  # need to separate out a method that returns payer id. same for item_member.
  # change data value for respective ids in index erb

  def item_member?(item)
    item_member = ItemMember.find_by(
      member: self,
      item:,
    )
    return item_member ? true : false
  end

  def item_member_id(item)
    item_member = ItemMember.find_by(
      member: self,
      item:,
    )
    return item_member.id
  end

  def consumed_items_amount
    total_amount = 0

    bill.items.each do |item|
      if item.member == current_user
        total_amount += (item.quantity * item.price)/item.members.count
      end
    end
  end

  def amount_owed(current_user)
    owe = 0
    splits = current_user.member.splits
    splits.each do |split|
      stats = split.get_split_stats
      stats.each do |stat|
        if stat[:payer_member].id == current_user.member.id
          owe += stat[:amount]
        end
      end
    end
    owe/100.00
  end

  def amount_to_pay(current_user)
    owe = 0
    splits = current_user.member.splits
    splits.each do |split|
      stats = split.get_split_stats
      stats.each do |stat|
        if stat[:payee_member].id == current_user.member.id
          owe += stat[:amount]
        end
      end
    end
    owe/100.00
  end

  # ---------------------

  def amount_paid(bill)
    return 0 unless bill.payers.map(&:member).include? self

    bill.total_amount / bill.payers.count unless bill.payers.count = 0
  end

  def total_consumed(bill)
    total = 0
    # get all the items i am a part of
    # items = bill.items
    items = Item.where(bill:).joins(:item_members).where(item_members: { member: self })
    items_without_members = Item.where(bill:).left_outer_joins(:item_members).where(item_members: { id: nil })

    (items + items_without_members).each do |item|
      price = item.price.to_f
      quantity = item.quantity
      # total_price = price * quantity
      share = (price * quantity) / (item.members.count.positive? ? item.members.count : item.bill.all_split_members.uniq.count)

      total += share
    end
    # for each item
    # get the total item price
    # get the total item members
    # get my own share

    # return sum of all my shares
    amount = (total - amount_paid(bill)) + bill.even_split_tax
    return { amount:, member: self }
  end
end
