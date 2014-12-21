require 'spec_helper'

describe Olfactory::Sequence do
  context "with no seed" do
    before(:example) do
      Olfactory.sequence :address do |n, options|
        "#{(n + (n % 2)) + 2} #{"#{options[:prefix]} " if options[:prefix]}BROADWAY"
      end
    end
    context "given nothing" do
      subject do
        Olfactory.generate(:address)
      end
      it { expect(subject).to eq("2 BROADWAY") }
    end
    context "given options" do
      subject do
        Olfactory.generate(:address, :prefix => "WEST")
      end
      it { expect(subject).to eq("2 WEST BROADWAY") }
    end
    context "given a block" do
      subject do
        Olfactory.generate(:address) do |n|
          "#{(n + (n % 2)) + 2} JOHN STREET"
        end
      end
      it { expect(subject).to eq("2 JOHN STREET") }
    end
    context "given options and a block" do
      subject do
        Olfactory.generate(:address, :suffix => "ROAD") do |n, options|
          "#{(n + (n % 2)) + 2} JOHN#{options[:suffix] ? " #{options[:suffix]}" : " STREET"}"
        end
      end
      it { expect(subject).to eq("2 JOHN ROAD") }
    end
  end
  context "with a seed" do
    before(:example) do
      Olfactory.sequence :address, :seed => 10 do |n, options|
        "#{(n + (n % 2))} #{"#{options[:prefix]} " if options[:prefix]}BROADWAY"
      end
    end
    context "given nothing" do
      subject do
        Olfactory.generate(:address)
      end
      it { expect(subject).to eq("10 BROADWAY") }
    end
    context "given options" do
      subject do
        Olfactory.generate(:address, :prefix => "WEST")
      end
      it { expect(subject).to eq("10 WEST BROADWAY") }
    end
    context "given a block" do
      subject do
        Olfactory.generate(:address) do |n|
          "#{(n + (n % 2))} JOHN STREET"
        end
      end
      it { expect(subject).to eq("10 JOHN STREET") }
    end
    context "given options and a block" do
      subject do
        Olfactory.generate(:address, :suffix => "ROAD") do |n, options|
          "#{(n + (n % 2))} JOHN#{options[:suffix] ? " #{options[:suffix]}" : " STREET"}"
        end
      end
      it { expect(subject).to eq("10 JOHN ROAD") }
    end
  end
  context "given sequential invocations" do
    before(:context) do
      Olfactory.sequence :address do |n, options|
        "#{(n + (n % 2)) + 2} #{"#{options[:prefix]} " if options[:prefix]}BROADWAY"
      end
    end
    it { expect(Olfactory.generate(:address)).to eq("2 BROADWAY") }
    it { expect(Olfactory.generate(:address)).to eq("4 BROADWAY") }
  end
end