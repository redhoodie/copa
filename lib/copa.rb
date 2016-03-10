require 'open-uri'
require 'json'

module Copa
  def self.is_live?
    Api::get_current_event.dig('item').present?
  rescue OpenURI::HTTPError => exception
    raise exception unless exception.message.to_i == 404
    return false
  end

  def self.live_event_time
    live_event = Api::get_current_event
    return nil if live_event.dig('eventStartTime')&.to_datetime.blank?

    EventTime.new(live_event)
  end

  def self.live_event
    live_event_time&.event
  end

  def self.next_event_time
    next_event_data = Api::get_upcomming_event_times&.first
    EventTime.new(next_event_data)
  end

  def self.next_event
    next_event_time&.event
  end

  def self.next_days_event_times
    next_event_date = next_event_time&.event_time.to_date
    return [] if next_event_date.blank?

    event_times = []

    Api::get_upcomming_event_times.each do |event_data|
      event_times.push EventTime.new(event_data) if event_data.dig('eventTime')&.to_date == next_event_date
    end

    event_times
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

  class EventTime < Event
    attr_accessor :event_time_id, :event_id, :event_time, :event_start_time, :event_end_time, :event_title, :event_time_doors_open_offset, :doors_open_offset, :video_offset, :chat_status, :offline_prayer_url, :prayer_tagline, :remote_login_url, :request_prayer_modal, :is_live
    def event
      Event.new(Api.get_event(self.event_id))
    end

    def time
      (event_time || event_start_time).to_datetime.in_time_zone
    end
    def end_time
      event_end_time.to_datetime.in_time_zone
    end
  end

  module Api
    BASE_URL = ENV['CHURCH_ONLINE_PLATFORM_API_URL'] || "http://#{ENV['CHURCH_ONLINE_PLATFORM_ID']}.churchonline.org/api/v1"
    
    # API end points
    def self.get_events
      api_call('events').dig 'response'
    end

    def self.get_current_event
      api_call("events/current?expand=event").dig 'response', 'item'
    rescue OpenURI::HTTPError => exception
      raise exception unless exception.message.to_i == 404
      return nil
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

          Rails.cache.fetch("cop-#{uri}", expires_in: 1.minutes) do
            response = JSON.parse(open(uri).read)
          end
        end
      end
  end
end
