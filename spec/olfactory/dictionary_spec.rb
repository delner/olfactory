require 'spec_helper'

describe Olfactory::Dictionary do
  before(:context) do
    Olfactory.dictionary :streets
  end

  context "given a value" do
    before(:context) do
      Olfactory.dictionaries[:streets][:borough => 1, :street => "BROADWAY"] = 10001
    end
    let(:key) do
      { :borough => 1, :street => "BROADWAY" }
    end
    let(:value) { 10001 }

    subject { Olfactory.dictionaries[:streets][key] }
    it { expect(subject).to eq(value) }
  end
end