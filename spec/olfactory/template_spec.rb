require 'spec_helper'

describe Olfactory::Template do
  context "items" do
    context "has_one" do
      before do
        Olfactory.template :widget do |t|
          t.has_one :doodad
        end
      end
      let(:value) { "doodad" }

      context "given a basic value" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad value
          end
        end
        it do
          expect(subject[:doodad]).to eq(value)
        end
      end
      context "given a block value" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad { value }
          end
        end
        it do
          expect(subject[:doodad]).to eq(value)
        end
      end
      context "with alias" do
        before do
          Olfactory.template :widget do |t|
            t.has_one :doodad, :alias => :foo
          end
        end
        context "given a basic value" do
          subject do
            Olfactory.build_template :widget do |t|
              t.foo value
            end
          end
          it do
            expect(subject[:doodad]).to eq(value)
          end
        end
        context "given a block value" do
          subject do
            Olfactory.build_template :widget do |t|
              t.foo { value }
            end
          end
          it do
            expect(subject[:doodad]).to eq(value)
          end
        end
      end
    end
    context "has_many" do
      before do
        Olfactory.template :widget do |t|
          t.has_many :doodad
        end
      end
      let(:value) { "doodad" }

      context "given a basic value" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad value
          end
        end
        it do
          expect(subject[:doodad]).to eq([value])
        end
      end
      context "given a block value" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad { value }
          end
        end
        it do
          expect(subject[:doodad]).to eq([value])
        end
      end
      context "with alias" do
        before do
          Olfactory.template :widget do |t|
            t.has_many :doodad, :alias => :foo
          end
        end
        context "given a basic value" do
          subject do
            Olfactory.build_template :widget do |t|
              t.foo value
            end
          end
          it do
            expect(subject[:doodad]).to eq([value])
          end
        end
        context "given a block value" do
          subject do
            Olfactory.build_template :widget do |t|
              t.foo { value }
            end
          end
          it do
            expect(subject[:doodad]).to eq([value])
          end
        end
      end
      context "with singular" do
        before do
          Olfactory.template :widget do |t|
            t.has_many :doodads, :singular => :doodad
          end
        end
        context "given a basic value" do
          subject do
            Olfactory.build_template :widget do |t|
              t.doodad value
            end
          end
          it do
            expect(subject[:doodads]).to eq([value])
          end
        end
        context "given a block value" do
          subject do
            Olfactory.build_template :widget do |t|
              t.doodad { value }
            end
          end
          it do
            expect(subject[:doodads]).to eq([value])
          end
        end
      end
      context "as named" do
        before do
          Olfactory.template :widget do |t|
            t.has_many :doodad, :named => :true
          end
        end
        context "given a name & basic value" do
          subject do
            Olfactory.build_template :widget do |t|
              t.doodad :foo, value
            end
          end
          it do
            expect(subject[:doodad][:foo]).to eq(value)
          end
        end
        context "given a name & block value" do
          subject do
            Olfactory.build_template :widget do |t|
              t.doodad :foo do
                value
              end
            end
          end
          it do
            expect(subject[:doodad][:foo]).to eq(value)
          end
        end
        context "given a no name" do
          subject do
            Olfactory.build_template :widget do |t|
              t.doodad
            end
          end
          it do
            expect { subject }.to raise_error
          end
        end
        context "given a no name & numeric value" do
          subject do
            Olfactory.build_template :widget do |t|
              t.doodad 1
            end
          end
          it do
            expect { subject }.to raise_error
          end
        end
      end
    end
  end
end


