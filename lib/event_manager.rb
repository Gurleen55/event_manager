require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

# initializing variables outside of the blocks so they could be accessible everywhere
hours = []
j = 0
days = []

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials

  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  phone_number.each_char.with_index do |char, index|
    unless phone_number[index].to_i.to_s == phone_number[index]
      phone_number[index] = " "
    end
  end
  phone_number.gsub!(/\s+/, "")
  if phone_number.length == 10
   phone_number
  elsif phone_number.length == 11 && phone_number[0].to_i == 1
    phone_number[1..phone_number.length]
  else
    "it's a bad phone number"
  end
end

def fix_date(date)
  parts = date.split("/")
  parts.map.with_index do |date, index|
    index == parts.length - 1 ? date.rjust(4, "20") : date.rjust(2, "0")
  end.join('/')
end

def fix_time(time)
  parts = time.split(':')
  parts.map {|part| part.rjust(2, "0")}.join(':')
end

puts 'Event Manager Initialized!'

# lines = File.readlines('event_attendees.csv')
# row_index = 0
# lines.each_with_index do |line, index|
#   next if index == 0
#   columns = line.split(",")
#   name = columns[2]
#   puts name
# end

contents = CSV.open(
  'event_attendees.csv', 
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
contents.each do |row|

  id = row[0] 

  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  reg_date_time = row[:regdate].split(' ')
  date, time = reg_date_time
  
  normalized_date = "#{fix_date(date)} #{fix_time(time)}"
  parsed_time = Time.strptime(normalized_date, "%m/%d/%Y %H:%M")
  hours[j] = parsed_time.hour
  j += 1

  days << parsed_time.strftime("%A")

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

end






hours_hash = hours.reduce(Hash.new(0)) do |result, hour|
  result[hour] = result[hour] + 1
  result
end

max_value = hours_hash.values.max

hour_maximum = []
hours_hash.each do |key, value|
  if max_value == value
    hour_maximum << key
  end
end

puts "the hours that we can target are #{hour_maximum} and day can be #{days.max}"

