require "sinatra"
require "sinatra/reloader"
require 'tilt/erubis'

not_found do
  redirect '/'
end

before do
  @contents = File.readlines('data/toc.txt')
end

helpers do
  def in_paragraphs(content)
    content.split("\n\n").each_with_index.map do |paragraph, num|
      "<p id=paragraph#{num}>#{paragraph}</p>"
    end.join
  end

  def each_chapter
    @contents.each_with_index do |name, index|
      number = index + 1
      contents = File.read("data/chp#{number}.txt")
      yield number, name, contents
    end
  end

  def chapters_matching(query)
    results = []
    return results unless query

    each_chapter do |chapter_number, name, contents|
      matches = {}
      each_paragraph(contents) do |paragraph, paragraph_number|
        matches[paragraph_number] = paragraph if paragraph.include?(query)
      end
      results << { name: name, number: chapter_number, paragraphs: matches } if matches.any?
    end

    results
  end
  
  def each_paragraph(chapter)
    chapter.split("\n\n").each_with_index do |paragraph, index|
      yield paragraph, index
    end
  end
  
  def bold_matching_text(text, query)
    text.gsub(query, "<b>#{query}</b>")
  end
  
  def paragraph_matching(chapter_number, query)
    matches = []
    chapter = File.read("data/chp#{chapter_number}.txt")
    
    each_paragraph(chapter) do |paragraph|
      matches << paragraph if paragraph.include?(query)
    end

    matches
  end
end

get "/" do
  @title = 'The Adventures of Sherlock Holmes'
  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  title = @contents[number - 1]

  redirect "/" unless (1..@contents.size).cover?(number)
  @title = "Chapter #{number}: #{title}"
  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end

get "/search" do
  @results = chapters_matching(params[:query])
  erb :search
end
