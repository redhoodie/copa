require 'open-uri'
require 'json'

module Copa
  def self.is_live?
    Api::current_event.dig('item').present?
  rescue OpenURI::HTTPError => exception
    raise exception unless exception.message.to_i == 404
    return false
  end

  def self.live_event_time
    live_date_time = Api::get_current_event.dig('eventStartTime')&.to_datetime
    return nil if live_date_time.blank?

    Api::get_upcomming_event_times.each do |event_data|
      return EventTime.new(event_data) if event_data.dig('eventTime')&.to_datetime == live_date_time
    end

    nil
  end

  def self.live_event
    live_event_time&.event
  end

  def self.next_event
    next_event_data = Api::get_upcomming_event_times&.first
    EventTime.new(next_event_data).event
  end

  def self.next_days_event_times
    next_event_date = next_event&.time
    return [] if next_event_date.blank?

    event_times = []

    Api::get_upcomming_event_times.each do |event_data|
      event_times.push EventTime.new(event_data) if event_data.dig('eventTime')&.to_date == next_event_date
    end

    events
  end

  class Base
    include ActiveModel::Model

    def initialize(data)
      underscored_keys_data = {}

      data.each do |key, value|
        underscored_keys_data[key.to_s.underscore] = value
      end

      super(underscored_keys_data)
    end
  end

  class Event < Base
    attr_accessor :id, :organization_id, :description, :duration, :enabled, :speaker, :title, :event_notes, :volunteer_notes, :facebook_message, :twitter_message, :email_message, :social_link, :slides_paused, :enabled_features, :custom_tab, :video_profile_status
  end

  class EventTime < Base
    attr_accessor :event_time_id, :event_id, :event_time, :event_end_time, :event_title, :event_time_doors_open_offset
    def event
      Event.new(Api.get_event(self.event_id))
    end

    def time
      event_time.to_datetime
    end
    def end_time
      event_end_time.to_datetime
    end
  end

  module Api
    #BASE_URL = "http://#{ENV['CHURCH_ONLINE_PLATFORM_ID']}.churchonline.org/api/v1"
    BASE_URL = "http://live.life.church/api/v1/"
    EXPIRES = proc { 1.minutes }
    
    # API end points
    def self.get_events
      api_call('events').dig 'response'
    end

    def self.get_current_event
      api_call("events/current").dig 'response', 'item'
    end

    def self.get_upcomming_event_times
      api_call('upcoming_event_times').dig 'response', 'items'
    end

    def self.get_event(event_id)
      api_call("events/#{event_id}").dig 'response'
    end

    private
      def self.api_call(url, params = {})
        begin
          uri = if params.count > 0
              BASE_URL + '/' + url + '?' + params.to_query
            else
              BASE_URL + '/' + url
            end

          Rails.cache.fetch("cop-#{uri}", expires_in: EXPIRES.call) do
            response = JSON.parse(open(uri).read)
          end
        end
      end
  end
end
