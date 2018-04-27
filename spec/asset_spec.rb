require 'spec_helper'

describe ContentfulModel::Asset do
  before :each do
    ContentfulModel.configure do |config|
      config.space = 'cfexampleapi'
      config.access_token = 'b4c0n73n7fu1'
    end
  end

  describe 'class methods' do
    it '.all' do
      vcr('asset/all') {
        assets = described_class.all
        expect(assets).to be_a ::Contentful::Array
        expect(assets.first).to be_a described_class
        expect(assets.first.id).to eq 'nyancat'
      }
    end

    it '.find' do
      vcr('asset/find') {
        asset = described_class.find('nyancat')
        expect(asset).to be_a described_class
        expect(asset.id).to eq 'nyancat'
      }
    end
  end

  describe 'queries' do
    it '#resize' do
      vcr('asset/find') {
        asset = described_class.find('nyancat')
        url = asset.resize(10, 20).load

        expect(url).to include('w=10')
        expect(url).to include('h=20')
      }
    end

    it '#width' do
      vcr('asset/find') {
        asset = described_class.find('nyancat')
        url = asset.width(20).load

        expect(url).to include('w=20')
      }
    end

    it '#height' do
      vcr('asset/find') {
        asset = described_class.find('nyancat')
        url = asset.height(10).load

        expect(url).to include('h=10')
      }
    end

    it '#format' do
      vcr('asset/find') {
        asset = described_class.find('nyancat')
        url = asset.format('jpg').load

        expect(url).to include('fm=jpg')
      }
    end

    it '#jpeg_quality' do
      vcr('asset/find') {
        asset = described_class.find('nyancat')
        url = asset.jpeg_quality(80).load

        expect(url).to include('fm=jpg')
        expect(url).to include('q=80')
      }
    end

    it '#png_8bit' do
      vcr('asset/find') {
        asset = described_class.find('nyancat')
        url = asset.png_8bit.load

        expect(url).to include('fm=png')
        expect(url).to include('fl=png8')
      }
    end

    it '#resize_behavior' do
      vcr('asset/find') {
        asset = described_class.find('nyancat')
        url = asset.resize_behavior('thumb').load

        expect(url).to include('fit=thumb')
      }
    end

    it '#thumbnail_focused_on' do
      vcr('asset/find') {
        asset = described_class.find('nyancat')
        url = asset.thumbnail_focused_on('face').load

        expect(url).to include('fit=thumb')
        expect(url).to include('f=face')
      }
    end

    it '#rounded_corners' do
      vcr('asset/find') {
        asset = described_class.find('nyancat')
        url = asset.rounded_corners(20).load

        expect(url).to include('r=20')
      }
    end

    it '#padded_background_color' do
      vcr('asset/find') {
        asset = described_class.find('nyancat')
        url = asset.padded_background_color('rgb:ffffff').load

        expect(url).to include('fit=pad')
        expect(url).to include('bg=rgb%3Affffff') # '%3A' is the urlencoded hexcode for ':'
      }
    end

    it 'chaining' do
      vcr('asset/find') {
        asset = described_class.find('nyancat')
        url = asset.resize(10, 20).rounded_corners(30).png_8bit.thumbnail_focused_on('face').load

        expect(url).to include('w=10')
        expect(url).to include('h=20')
        expect(url).to include('r=30')
        expect(url).to include('fm=png')
        expect(url).to include('fl=png8')
        expect(url).to include('fit=thumb')
        expect(url).to include('f=face')
      }
    end
  end
end
