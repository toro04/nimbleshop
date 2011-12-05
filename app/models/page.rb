class Page < ActiveRecord::Base

  before_create :set_permalink

  def url
    "/pages/#{self.permalink}"
  end

  private

  # TODO move this to a separate gem
  def set_permalink
    permalink = self.name.parameterize
    counter = 2

    while self.class.exists?(permalink: permalink) do
      permalink = "#{permalink}-#{counter}"
      counter = counter + 1
    end

    self.permalink ||= permalink
  end

end
