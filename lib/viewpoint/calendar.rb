#############################################################################
# Copyright © 2009 Dan Wanek <dan.wanek@gmail.com>
#
#
# This file is part of Viewpoint.
# 
# Viewpoint is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
# 
# Viewpoint is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with Viewpoint.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################
$:.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'icalendar'
require 'wsdl/exchangeServiceBinding'
# --- Folder Types ---
require 'folder'
# --- Item Types ---
require 'calendar_item'
#require 'meeting_request'



class Viewpoint::CalendarFolder < Viewpoint::Folder
	include Viewpoint

	# initialize with an item of CalendarFolderType
	def initialize(folder)
		# Call initialize in the 
		super(folder)
	end

	def get_todays_events
		get_events(DateTime.parse(Date.today.to_s), DateTime.parse(Date.today.next.to_s))
	end

	def get_weeks_events
		start_date = Date.today
		end_date = (start_date + ( 6 - start_date.wday))

		get_events(DateTime.parse(start_date.to_s), DateTime.parse(end_date.to_s))
	end

	# Get events between a certain time period.  Defaults to "today"
	# Input: DateTime of start, DateTime of end
	# You can get a year of events by passing 'nil, nil', but you should really consider using synchronization then.
	# This method will return an Array of CalendarItem
	def get_events(start_time = (DateTime.parse(Date.today.to_s)), end_time = (DateTime.parse(Date.today.next.to_s)))
		find_item_t = FindItemType.new
		find_item_t.xmlattr_Traversal = ItemQueryTraversalType::Shallow
		item_shape = ItemResponseShapeType.new(DefaultShapeNamesType::Default, false)

		find_item_t.itemShape = item_shape
		
		folder_ids = NonEmptyArrayOfBaseFolderIdsType.new()
		dist_folder = DistinguishedFolderIdType.new
		dist_folder.xmlattr_Id = DistinguishedFolderIdNameType.new(@display_name.downcase)
		folder_ids.distinguishedFolderId = dist_folder
		find_item_t.parentFolderIds = folder_ids
		
		# If we pass nil, force times to be:
		# 	start:  1 years ago
		# 	end:	1 years from now
		cal_span =  CalendarViewType.new
		if ( start_time == nil or end_time == nil)
			cal_span.xmlattr_StartDate = DateTime.parse((Date.today - 365).to_s).to_s
			cal_span.xmlattr_EndDate = DateTime.parse((Date.today + 365).to_s).to_s
			find_item_t.calendarView = cal_span
		else
			cal_span.xmlattr_StartDate = start_time.to_s
			cal_span.xmlattr_EndDate = end_time.to_s
			find_item_t.calendarView = cal_span
		end

		resp = find_items(find_item_t)
		if resp != nil
			cal_items = []

			resp.rootFolder.items.calendarItem.each do |cali|
				cal_items << CalendarItem.new(cali, self)
			end
			# TODO: Handle the following types of Calendar data
			# meetingMessage
			# meetingRequest
			# meetingResponse
			# meetingCancellation

			return cal_items
		else
			return resp  # return nil
		end
	end


	# Returns an Icalendar::Calendar object
	# Input: DateTime of start, DateTime of end
	def to_ical(dtstart = nil, dtend = nil)
		ical = Icalendar::Calendar.new
		events = get_events(dtstart, dtend)
		events.each do |ev|
			ical.add_event(ev.to_ical_event)
		end
		return ical
	end


	# See docs for Folder::get_item
	def get_item(item_id)
		cali = super(item_id, "calendarItem", true)
	end

  def get_event(item_id)
    begin
      return CalendarItem.new(get_item(item_id), self)
    rescue InvalidEWSItemError => e
      return nil
    end
  end
end

