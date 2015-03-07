class Conference < ActiveRecord::Base
  validates_presence_of :title
  validates_presence_of :date_range
  after_validation :smart_add_url_protocol

  # Associations
  belongs_to :creation_user, :class => User
  has_many :followings, :dependent => :destroy
  has_many :followers, :through => :followings, :source => :user
  has_many :comments

  validates_date :start_date
  validates_date :end_date
  validates_date :end_date, :on_or_after => :start_date

  extend FriendlyId
  friendly_id :title, :use => :slugged

  scope :occurs_within, ->(date_range) {
    where('NOT(start_date > ? OR end_date < ?)', date_range.end, date_range.begin)
  }
  scope :order_by_date, -> { order(:start_date, :end_date) }

  geocoded_by :location
  after_validation :geocode

  extend DateRangeAccessor
  date_range_accessor :date_range, :start_date, :end_date

  # Elasticsearch
  searchkick word_start: [:title]

  # Version history
  has_paper_trail

  attr_writer :followers_count
  def follower_count
    @follower_count ||= followers.count
  end

  # Prevent N queries to load the count of followers on a collection
  def self.eager_load_followers_count(conferences)
    conference_ids = conferences.map(&:id)
    followers_count = Following.where(:conference_id => conference_ids).group(:conference_id).count
    conferences.each do |conference|
      conference.followers_count = followers_count[conference.id]
    end
  end

  # Add or remove a follower
  def follow(user)
    raise ArgumentError, "Must provide a user" if user.nil?

    follower = followers.find_by_id(user.id)
    if follower.nil?
      followers << user
    else
      followers.delete user
    end
  end

  def creation_user
    super || User.deleted
  end

  protected

  def smart_add_url_protocol
    if url.present? && !(url =~ /\Ahttp(s)?:\/\//)
      self.url = "http://#{url}"
    end
  end
end
