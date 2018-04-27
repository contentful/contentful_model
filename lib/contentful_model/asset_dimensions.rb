require_relative 'asset_dimension_query'

module ContentfulModel
  # Module to extend Asset with Image API capabilities
  module AssetDimensions
    def query
      ContentfulModel::AssetDimensionQuery.new(self)
    end

    def resize(width = nil, height = nil)
      query.resize(width, height)
    end

    def width(w)
      query.width(w)
    end

    def height(h)
      query.height(h)
    end

    def format(fm)
      query.format(fm)
    end

    def jpeg_quality(q)
      query.jpeg_quality(q)
    end

    def png_8bit
      query.png_8bit
    end

    def resize_behavior(fit)
      query.resize_behavior(fit)
    end

    def thumbnail_focused_on(f)
      query.thumbnail_focused_on(f)
    end

    def rounded_corners(r)
      query.rounded_corners(r)
    end

    def padded_background_color(bg)
      query.padded_background_color(bg)
    end

    def load
      query.load
    end
  end
end
