class Tweet < ActiveRecord::Base
  has_neighbors :embedding
end
