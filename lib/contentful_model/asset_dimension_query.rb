module ContentfulModel
  # Module for extending Asset with Image API capabilities
  class AssetDimensionQuery
    attr_reader :asset, :query

    def initialize(asset)
      @asset = asset
      @query = {}
    end

    def resize(width = nil, height = nil)
      self.width(width) unless width.nil?
      self.height(height) unless height.nil?
      self
    end

    def width(w)
      query[:w] = w
      self
    end

    def height(h)
      query[:h] = h
      self
    end

    def format(fm)
      query[:fm] = fm
      self
    end

    def jpeg_quality(q)
      query[:fm] = 'jpg'
      query[:q] = q
      self
    end

    def png_8bit
      query[:fm] = 'png'
      query[:fl] = 'png8'
      self
    end

    def resize_behavior(fit)
      query[:fit] = fit
      self
    end

    def thumbnail_focused_on(f)
      query[:fit] = 'thumb'
      query[:f] = f
      self
    end

    def rounded_corners(r)
      query[:r] = r
      self
    end

    def padded_background_color(bg)
      query[:fit] = 'pad'
      query[:bg] = bg
      self
    end

    def load
      asset.url(query)
    end
  end
end
