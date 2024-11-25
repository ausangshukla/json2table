# This module contains the entire source code needed to
# convert a JSON blob into a HTML Table.
#
# The gem is at http://rubygems.org/gems/json2table
# To install the gem, run command `gem install json2table`
# @author CodeExpress

require 'json'
require 'set'

module Json2table
  
  def self.get_html_table(json_str, options = {})
    html = ""
    begin
      if json_str.is_a?(Hash)
        hash = json_str
      else
        hash = JSON.parse(json_str)
      end
    rescue Exception => e
      puts "JSON2TABLE:: Input not a valid JSON, provide valid JSON object"
      #puts e.message
      throw e
    end
    html = self.create_table(hash, options)
    return html
  end


def self.create_table(hash, options, level=0)
  # Return empty string if hash is nil or empty
  return '' if hash.nil? || (hash.respond_to?(:empty?) && hash.empty?)
  
  html = start_table_tag(options)
  if hash.is_a?(Array)
    html += process_array(hash, options, level)
  elsif hash.is_a?(Hash)
    hash.each do |key, value|
      html += "<tr><th>#{to_human(key)}</th>\n"
      html += "<td>"
      if value.is_a?(Hash)
        html += create_table(value, options, level + 1)
      elsif value.is_a?(Array)
        html += process_array(value, options, level + 1)
      else
        html += "#{value}</td></tr>\n"
      end
    end
  else
    html += "<tr><td>#{hash}</td></tr>\n"
  end
  html += close_table_tag
  return html
end


def self.process_array(arr, options, level)
  # Return empty string if arr is nil or empty
  return '' if arr.nil? || arr.empty?

  html = ""
  if arr[0].is_a?(Hash)
    keys = similar_keys?(arr)
    if keys
      html += create_vertical_table_from_array(arr, keys, options, level)
    else
      arr.each do |h|
        html += create_table(h, options, level)
      end
    end
  else
    arr.each do |element|
      html += "#{element}<br/>\n"
    end
  end
  return html
end


  # This method checks if all the individual array items
  # are hashes with similar keys.
 def self.similar_keys?(arr)
  # Return nil if arr is nil or empty
  return nil if arr.nil? || arr.empty?

  previous_keys = Set.new
  current_keys   = Set.new
  arr.each do |hash|
    return nil unless hash.is_a?(Hash)
    current_keys = hash.keys.to_set
    if previous_keys.empty?
      previous_keys = current_keys
    else
      return nil unless (previous_keys ^ current_keys).empty?
      previous_keys = current_keys
    end
  end
  return arr[0].keys
end


  # creates a vertical table of following form for the array of hashes like this:
  #        ---------------------
  #       | key1 | key2 | key3  |
  #        ---------------------
  #       | val1 | val2 | val3  |
  #       | val4 | val5 | val6  |
  #       | val9 | val8 | val7  |
  #        ---------------------

  def self.create_vertical_table_from_array(array_of_hashes, keys, options, level)
  html = start_table_tag(options)
  
  # Only add <thead> at the outermost level
  if level == 0
    html += "<thead>\n"
  end

  # Generate header row
  html += "<tr>\n"
  keys.each do |key|
    html += "<th>#{to_human(key)}</th>\n"
  end
  html += "</tr>\n"

  # Close <thead> and open <tbody> at the outermost level
  if level == 0
    html += "</thead>\n<tbody>\n"
  end

  # Generate data rows
  array_of_hashes.each do |hash|
    html += "<tr>\n"
    keys.each do |key|
      if hash[key].is_a?(Hash)
        html += "<td>#{create_table(hash[key], options, level + 1)}</td>\n"
      elsif hash[key].is_a?(Array)
        html += "<td>\n"
        html += process_array(hash[key], options, level + 1)
        html += "</td>\n"
      else
        html += "<td>#{hash[key]}</td>\n"
      end
    end
    html += "</tr>\n"
  end

  # Close <tbody> at the outermost level
  if level == 0
    html += "</tbody>\n"
  end

  html += self.close_table_tag
end

  
  def self.start_table_tag(options)
    "<table class='#{options[:table_class]}' 
            style='#{options[:table_style]}'
            #{options[:table_attributes]} >\n"
  end

  def self.close_table_tag
    "</table>\n"
  end
  
  # turns CamelCase and snake_case keys to human readable strings
  # Input:  this_isA_mixedCAse_line-string
  # Output: "This Is A Mixed C Ase Line String"
  def self.to_human(key)
    key.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1 \2').
      gsub(/([a-z\d])([A-Z])/,'\1 \2').
      tr("-", " ").tr("_", " ").
      split.map {|word| word.capitalize}.join(" ")
  end
end
