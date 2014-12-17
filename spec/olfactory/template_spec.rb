require 'spec_helper'

describe Olfactory::Template do
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
    context "with an alias" do
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
    context "with an alias" do
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
  context "embeds_one" do
    before do
      Olfactory.template :widget do |t|
        t.embeds_one :doodad
      end
      Olfactory.template :doodad do |t|
        t.has_one :gizmo
      end
    end
    let(:value) { "gizmo" }

    context "given no value" do
      subject do
        Olfactory.build_template :widget do |t|
          t.doodad
        end
      end
      it do
        expect(subject[:doodad]).to eq({})
      end
    end
    context "given a symbol value" do
      before do
        Olfactory.template :widget do |t|
          t.embeds_one :doodad
        end
        Olfactory.template :doodad do |t|
          t.has_one :gizmo
          t.preset :shiny do |p|
            p.gizmo "shiny #{value}"
          end
        end
      end
      context "that matches a defined preset" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad :shiny
          end
        end
        it do
          # Expect it to invoke a preset on the subtemplate
          expect(subject[:doodad][:gizmo]).to eq("shiny #{value}")
        end
      end
      context "that does not match a defined preset" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad :rusty
          end
        end
        it do
          # Expect it to invoke a preset on the subtemplate
          expect{ subject }.to raise_error
        end
      end
    end
    context "given a block value" do
      subject do
        Olfactory.build_template :widget do |t|
          t.doodad { |d| d.gizmo value }
        end
      end
      it do
        expect(subject[:doodad]).to eq({ :gizmo => value })
      end
    end
    context "with an alias" do
      before do
        Olfactory.template :widget do |t|
          t.embeds_one :doodad, :alias => :foo
        end
        Olfactory.template :doodad do |t|
          t.has_one :gizmo
        end
      end
      context "given no value" do
        subject do
          Olfactory.build_template :widget do |t|
            t.foo
          end
        end
        it do
          expect(subject[:doodad]).to eq({})
        end
      end
    end
    context "with template name" do
      before do
        Olfactory.template :widget do |t|
          t.embeds_one :doodad, :template => :thingamabob
        end
        Olfactory.template :thingamabob do |t|
          t.has_one :gizmo
        end
      end
      context "given no value" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad
          end
        end
        it do
          expect(subject[:doodad]).to eq({})
        end
      end
    end
  end
  context "embeds_many" do
    before do
      Olfactory.template :widget do |t|
        t.embeds_many :doodad
      end
      Olfactory.template :doodad do |t|
        t.has_one :gizmo
      end
    end
    let(:value) { "gizmo" }

    context "given no value" do
      subject do
        Olfactory.build_template :widget do |t|
          t.doodad
        end
      end
      it do
        expect(subject[:doodad]).to eq([{}])
      end
    end
    context "given an integer value" do
      subject do
        Olfactory.build_template :widget do |t|
          t.doodad 2
        end
      end
      it do
        expect(subject[:doodad]).to eq([{}, {}])
      end
    end
    context "given a symbol value" do
      before do
        Olfactory.template :widget do |t|
          t.embeds_many :doodad
        end
        Olfactory.template :doodad do |t|
          t.has_one :gizmo
          t.preset :shiny do |p|
            p.gizmo "shiny #{value}"
          end
        end
      end
      context "that matches a defined preset" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad :shiny
          end
        end
        it do
          # Expect it to invoke a preset on the subtemplate
          expect(subject[:doodad]).to eq([{ :gizmo => "shiny #{value}" }])
        end
      end
      context "that does not match a defined preset" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad :rusty
          end
        end
        it do
          # Expect it to invoke a preset on the subtemplate
          expect{ subject }.to raise_error
        end
      end
    end
    context "given a symbol & integer value" do
      before do
        Olfactory.template :widget do |t|
          t.embeds_many :doodad
        end
        Olfactory.template :doodad do |t|
          t.has_one :gizmo
          t.preset :shiny do |p|
            p.gizmo "shiny #{value}"
          end
        end
      end
      context "that matches a defined preset" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad :shiny, 2
          end
        end
        it do
          # Expect it to invoke a preset on the subtemplate
          expect(subject[:doodad]).to eq([{ :gizmo => "shiny #{value}" }, { :gizmo => "shiny #{value}" }])
        end
      end
      context "that does not match a defined preset" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad :rusty, 2
          end
        end
        it do
          # Expect it to invoke a preset on the subtemplate
          expect{ subject }.to raise_error
        end
      end
    end
    context "given an integer & symbol value" do
      before do
        Olfactory.template :widget do |t|
          t.embeds_many :doodad
        end
        Olfactory.template :doodad do |t|
          t.has_one :gizmo
          t.preset :shiny do |p|
            p.gizmo "shiny #{value}"
          end
        end
      end
      context "that matches a defined preset" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad 2, :shiny
          end
        end
        it do
          # Expect it to invoke a preset on the subtemplate
          expect(subject[:doodad]).to eq([{ :gizmo => "shiny #{value}" }, { :gizmo => "shiny #{value}" }])
        end
      end
      context "that does not match a defined preset" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad 2, :rusty
          end
        end
        it do
          # Expect it to invoke a preset on the subtemplate
          expect{ subject }.to raise_error
        end
      end
    end
    context "given a block value" do
      subject do
        Olfactory.build_template :widget do |t|
          t.doodad { |d| d.gizmo value }
        end
      end
      it do
        expect(subject[:doodad]).to eq([{ :gizmo => value }])
      end
    end
    context "given an integer and block value" do
      subject do
        Olfactory.build_template :widget do |t|
          t.doodad 2 do |d|
            d.gizmo value
          end
        end
      end
      it do
        expect(subject[:doodad]).to eq([{ :gizmo => value }, { :gizmo => value }])
      end
    end
    context "given sequential invocations" do
      context "with no value" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad
            t.doodad
          end
        end
        it do
          expect(subject[:doodad]).to eq([{}, {}])
        end
      end
      context "with a symbol value" do
        before do
          Olfactory.template :widget do |t|
            t.embeds_many :doodad
          end
          Olfactory.template :doodad do |t|
            t.has_one :gizmo
            t.preset :shiny do |p|
              p.gizmo "shiny #{value}"
            end
          end
        end
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad :shiny
            t.doodad :shiny
          end
        end
        it do
          expect(subject[:doodad]).to eq([{:gizmo => "shiny #{value}"}, {:gizmo => "shiny #{value}"}])
        end
      end
      context "with an integer value" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad 1
            t.doodad 2
          end
        end
        it do
          expect(subject[:doodad]).to eq([{}, {}, {}])
        end
      end
      context "with a block value" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad { |d| d.gizmo value }
            t.doodad { |d| d.gizmo value }
          end
        end
        it do
          expect(subject[:doodad]).to eq([{ :gizmo => value }, { :gizmo => value }])
        end
      end
    end
    context "with an alias" do
      before do
        Olfactory.template :widget do |t|
          t.embeds_many :doodad, :alias => :foo
        end
        Olfactory.template :doodad do |t|
          t.has_one :gizmo
        end
      end
      context "given no value" do
        subject do
          Olfactory.build_template :widget do |t|
            t.foo
          end
        end
        it do
          expect(subject[:doodad]).to eq([{}])
        end
      end
    end
    context "with singular" do
      before do
        Olfactory.template :widget do |t|
          t.embeds_many :doodad, :singular => :dood
        end
        Olfactory.template :doodad do |t|
          t.has_one :gizmo
        end
      end
      context "given no value" do
        subject do
          Olfactory.build_template :widget do |t|
            t.dood
          end
        end
        it do
          expect(subject[:doodad]).to eq([{}])
        end
      end
    end
    context "as named" do
      before do
        Olfactory.template :widget do |t|
          t.embeds_many :doodad, :named => true
        end
        Olfactory.template :doodad do |t|
          t.has_one :gizmo
        end
      end
      context "given a name & no value" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad :one
          end
        end
        it do
          expect(subject[:doodad][:one]).to eq({})
        end
      end
      context "given a name & block value" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodad :one do |d|
              d.gizmo value
            end
          end
        end
        it do
          expect(subject[:doodad][:one]).to eq({ :gizmo => value })
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
    context "with template name" do
      before do
        Olfactory.template :widget do |t|
          t.embeds_many :doodads, :template => :doodad
        end
        Olfactory.template :doodad do |t|
          t.has_one :gizmo
        end
      end
      context "given no value" do
        subject do
          Olfactory.build_template :widget do |t|
            t.doodads
          end
        end
        it do
          expect(subject[:doodads]).to eq([{}])
        end
      end
    end
  end
  context "macros" do
    before do
      Olfactory.template :widget do |t|
        t.has_one :doodad
        t.macro :make_shiny do |m, v|
          m.doodad "shiny #{m[:doodad]}"
        end
      end
    end
    let(:value) { "doodad" }

    subject do
      Olfactory.build_template :widget do |t|
        t.doodad value
        t.make_shiny
      end
    end
    it "should execute its block" do
      expect(subject[:doodad]).to eq("shiny #{value}")
    end

    context "with parameters" do
      before do
        Olfactory.template :widget do |t|
          t.has_one :doodad
          t.macro :make do |m, adj, adj2|
            m.doodad "#{adj.to_s} #{adj2.to_s} #{m[:doodad]}"
          end
        end
      end
      subject do
        Olfactory.build_template :widget do |t|
          t.doodad value
          t.make :very, :shiny
        end
      end
      it "receives them on invocation" do
        expect(subject[:doodad]).to eq("very shiny #{value}")
      end
    end
  end
  context "transients" do
    # TODO: Add examples
  end
  context "defaults" do
    # TODO: Add examples
  end
end


