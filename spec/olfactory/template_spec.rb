require 'spec_helper'

describe Olfactory::Template do
  context "has_one" do
    before(:context) do
      Olfactory.template :widget do |t|
        t.has_one :doodad
      end
    end
    let(:value) { "doodad" }

    context "given a basic value" do
      subject do
        Olfactory.build :widget do |t|
          t.doodad value
        end
      end
      it do
        expect(subject[:doodad]).to eq(value)
      end
    end
    context "given a block value" do
      subject do
        Olfactory.build :widget do |t|
          t.doodad { value }
        end
      end
      it do
        expect(subject[:doodad]).to eq(value)
      end
    end
    context "with an alias" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.has_one :doodad, :alias => :foo
        end
      end
      context "given a basic value" do
        subject do
          Olfactory.build :widget do |t|
            t.foo value
          end
        end
        it do
          expect(subject[:doodad]).to eq(value)
        end
      end
      context "given a block value" do
        subject do
          Olfactory.build :widget do |t|
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
    before(:context) do
      Olfactory.template :widget do |t|
        t.has_many :doodad
      end
    end
    let(:value) { "doodad" }

    context "as generic collection" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.has_many :doodads, :singular => :doodad
        end
      end
      context "invoked as singular" do
        context "given a basic value" do
          subject do
            Olfactory.build :widget do |t|
              t.doodad value
            end
          end
          it do
            expect(subject[:doodads]).to eq([value])
          end
        end
        context "given a block value" do
          subject do
            Olfactory.build :widget do |t|
              t.doodad { value }
            end
          end
          it do
            expect(subject[:doodads]).to eq([value])
          end
        end
      end
      context "invoked as plural" do
        context "given an integer & block value" do
          subject do
            Olfactory.build :widget do |t|
              t.doodads 2 do
                value
              end
            end
          end
          it do
            expect(subject[:doodads]).to eq([value, value])
          end
        end
        context "given an array" do
          subject do
            Olfactory.build :widget do |t|
              t.doodads [value, value]
            end
          end
          it do
            expect(subject[:doodads]).to eq([value, value])
          end
        end
        context "given a splattered set of arguments" do
          subject do
            Olfactory.build :widget do |t|
              t.doodads value, value
            end
          end
          it do
            expect(subject[:doodads]).to eq([value, value])
          end
        end
      end
      context "given sequential invocations" do
        subject do
          Olfactory.build :widget do |t|
            t.doodad value
            t.doodads value, value
            t.doodad value
          end
        end
        it do
          expect(subject[:doodads]).to eq([value, value, value, value])
        end
      end
      context "with an alias" do
        before(:context) do
          Olfactory.template :widget do |t|
            t.has_many :doodads, :singular => :doodad, :alias => :foos
          end
        end
        context "given a basic value" do
          subject do
            Olfactory.build :widget do |t|
              t.foos value
            end
          end
          it do
            expect(subject[:doodads]).to eq([value])
          end
        end
        context "given a block value" do
          subject do
            Olfactory.build :widget do |t|
              t.foos { value }
            end
          end
          it do
            # Alias only applies to the plural context, not singular.
            expect(subject[:doodads]).to eq(nil)
          end
        end
      end
    end
    context "as named collection" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.has_many :doodads, :singular => :doodad, :named => :true
        end
      end
      context "invoked as singular" do
        context "given a name & basic value" do
          subject do
            Olfactory.build :widget do |t|
              t.doodad :foo, value
            end
          end
          it do
            expect(subject[:doodads][:foo]).to eq(value)
          end
        end
        context "given a name & block value" do
          subject do
            Olfactory.build :widget do |t|
              t.doodad :foo do
                value
              end
            end
          end
          it do
            expect(subject[:doodads][:foo]).to eq(value)
          end
        end
        context "given no name" do
          subject do
            Olfactory.build :widget do |t|
              t.doodad
            end
          end
          it do
            expect { subject }.to raise_error
          end
        end
        context "given no name & numeric value" do
          subject do
            Olfactory.build :widget do |t|
              t.doodad 1
            end
          end
          it do
            # It would have take "1" as the name, but the object would be nil.
            # Thus, not added.
            expect(subject[:doodads]).to eq(nil)
          end
        end
      end
      context "invoked as plural" do
        context "given a hash value" do
          subject do
            Olfactory.build :widget do |t|
              t.doodads :a => value
            end
          end
          it do
            expect(subject[:doodads]).to eq({ :a => value })
          end
        end
        context "given no name or value" do
          subject do
            Olfactory.build :widget do |t|
              t.doodads
            end
          end
          it do
            expect(subject).to eq({})
          end
        end
      end
      context "given sequential invocations" do
        subject do
          Olfactory.build :widget do |t|
            t.doodad :a, value
            t.doodads :b => value, :c => value
            t.doodad :d, value
          end
        end
        it do
          expect(subject[:doodads]).to eq({ :a => value,
                                            :b => value,
                                            :c => value,
                                            :d => value })
        end
      end
      context "with an alias" do
        before(:context) do
          Olfactory.template :widget do |t|
            t.has_many :doodads,  :singular => :doodad,
                                  :named => :true,
                                  :alias => :foos
          end
        end
        context "given a hash" do
          subject do
            Olfactory.build :widget do |t|
              t.foos :a => value
            end
          end
          it do
            expect(subject[:doodads]).to eq({:a => value})
          end
        end
        context "given a name and basic value" do
          subject do
            Olfactory.build :widget do |t|
              t.foos :a, value
            end
          end
          it do
            # Alias only applies to the plural context, not singular.
            expect(subject[:doodads]).to eq(nil)
          end
        end
      end
    end
  end
  context "embeds_one" do
    before(:context) do
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
        Olfactory.build :widget do |t|
          t.doodad
        end
      end
      it do
        expect(subject[:doodad]).to eq({})
      end
    end
    context "given a symbol value" do
      before(:context) do
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
          Olfactory.build :widget do |t|
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
          Olfactory.build :widget do |t|
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
        Olfactory.build :widget do |t|
          t.doodad { |d| d.gizmo value }
        end
      end
      it do
        expect(subject[:doodad]).to eq({ :gizmo => value })
      end
    end
    context "with an alias" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.embeds_one :doodad, :alias => :foo
        end
        Olfactory.template :doodad do |t|
          t.has_one :gizmo
        end
      end
      context "given no value" do
        subject do
          Olfactory.build :widget do |t|
            t.foo
          end
        end
        it do
          expect(subject[:doodad]).to eq({})
        end
      end
    end
    context "with template name" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.embeds_one :doodad, :template => :thingamabob
        end
        Olfactory.template :thingamabob do |t|
          t.has_one :gizmo
        end
      end
      context "given no value" do
        subject do
          Olfactory.build :widget do |t|
            t.doodad
          end
        end
        it do
          expect(subject[:doodad]).to eq({})
        end
      end
    end
    # context "with a before block" do
    #   before do
    #     Olfactory.template :widget do |t|
    #       t.embeds_one :doodad do |w|
    #         w.quality :dull
    #       end
    #       t.macro :quality do |m, type|
    #         m.transient :attribute, type.to_s
    #       end
    #     end
    #     Olfactory.template :doodad do |t|
    #       t.has_one :gizmo
    #       t.after do |d|
    #         d.gizmo "#{d.transients[:attribute]} #{value}"
    #       end
    #     end
    #   end
    #   let(:shiny) do
    #     Olfactory.build :widget do |w|
    #       w.quality :shiny
    #       w.doodad
    #     end
    #   end
    #   let(:dull) do
    #     Olfactory.build :widget do |w|
    #       w.doodad
    #     end
    #   end
    #   it { expect(shiny[:doodad][:gizmo]).to eq("shiny #{value}")}
    #   it { expect(dull[:doodad][:gizmo]).to eq("dull #{value}")}
    # end
  end
  context "embeds_many" do
    before(:context) do
      Olfactory.template :widget do |t|
        t.embeds_many :doodads
      end
      Olfactory.template :doodad do |t|
        t.has_one :gizmo
      end
    end
    let(:value) { "gizmo" }

    context "as generic collection" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.embeds_many :doodads, :singular => :doodad
        end
        Olfactory.template :doodad do |t|
          t.has_one :gizmo
        end
      end
      context "invoked as singular" do
        context "given no value" do
          subject do
            Olfactory.build :widget do |t|
              t.doodad
            end
          end
          it do
            expect(subject[:doodads]).to eq([{}])
          end
        end
        context "given a symbol value" do
          before(:context) do
            Olfactory.template :widget do |t|
              t.embeds_many :doodads, :singular => :doodad
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
              Olfactory.build :widget do |t|
                t.doodad :shiny
              end
            end
            it do
              # Expect it to invoke a preset on the subtemplate
              expect(subject[:doodads]).to eq([{ :gizmo => "shiny #{value}" }])
            end
          end
          context "that does not match a defined preset" do
            subject do
              Olfactory.build :widget do |t|
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
            Olfactory.build :widget do |t|
              t.doodad { |d| d.gizmo value }
            end
          end
          it do
            expect(subject[:doodads]).to eq([{ :gizmo => value }])
          end
        end
      end
      context "invoked as plural" do
        context "given an integer value" do
          subject do
            Olfactory.build :widget do |t|
              t.doodads 2
            end
          end
          it do
            expect(subject[:doodads]).to eq([{}, {}])
          end
        end
        context "given a symbol & integer value" do
          before(:context) do
            Olfactory.template :widget do |t|
              t.embeds_many :doodads, :singular => :doodad
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
              Olfactory.build :widget do |t|
                t.doodads :shiny, 2
              end
            end
            it do
              # Expect it to invoke a preset on the subtemplate
              expect(subject[:doodads]).to eq([{ :gizmo => "shiny #{value}" }, { :gizmo => "shiny #{value}" }])
            end
          end
          context "that does not match a defined preset" do
            subject do
              Olfactory.build :widget do |t|
                t.doodads :rusty, 2
              end
            end
            it do
              # Expect it to invoke a preset on the subtemplate
              expect{ subject }.to raise_error
            end
          end
        end
        context "given an integer & symbol value" do
          before(:context) do
            Olfactory.template :widget do |t|
              t.embeds_many :doodads, :singular => :doodad
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
              Olfactory.build :widget do |t|
                t.doodads 2, :shiny
              end
            end
            it do
              # Expect it to invoke a preset on the subtemplate
              expect(subject[:doodads]).to eq([{ :gizmo => "shiny #{value}" }, { :gizmo => "shiny #{value}" }])
            end
          end
          context "that does not match a defined preset" do
            subject do
              Olfactory.build :widget do |t|
                t.doodads 2, :rusty
              end
            end
            it do
              # Expect it to invoke a preset on the subtemplate
              expect{ subject }.to raise_error
            end
          end
        end
        context "given an integer and block value" do
          subject do
            Olfactory.build :widget do |t|
              t.doodads 2 do |d|
                d.gizmo value
              end
            end
          end
          it do
            expect(subject[:doodads]).to eq([{ :gizmo => value }, { :gizmo => value }])
          end
        end
      end
      context "given sequential invocations" do
        subject do
          Olfactory.build :widget do |t|
            t.doodad
            t.doodads 2
            t.doodad
          end
        end
        it do
          expect(subject[:doodads]).to eq([{}, {}, {}, {}])
        end
      end
      context "with an alias" do
        before(:context) do
          Olfactory.template :widget do |t|
            t.embeds_many :doodads, :singular => :doodad, :alias => :foos
          end
          Olfactory.template :doodad do |t|
            t.has_one :gizmo
          end
        end
        context "given an integer value" do
          subject do
            Olfactory.build :widget do |t|
              t.foos 2
            end
          end
          it do
            expect(subject[:doodads]).to eq([{},{}])
          end
        end
        context "given a block value" do
          subject do
            Olfactory.build :widget do |t|
              t.foos { |f| f.gizmo value }
            end
          end
          it do
            # Alias only applies to the plural context, not singular.
            expect { subject[:doodads] }.to raise_error
          end
        end
      end
    end
    context "as named collection" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.embeds_many :doodads, :singular => :doodad,
                                  :named => true
        end
        Olfactory.template :doodad do |t|
          t.has_one :gizmo
        end
      end
      context "invoked as singular" do
        context "given a name & no value" do
          subject do
            Olfactory.build :widget do |t|
              t.doodad :a
            end
          end
          it do
            expect(subject[:doodads][:a]).to eq({})
          end
        end
        context "given a name & symbol value" do
          before(:context) do
            Olfactory.template :widget do |t|
              t.embeds_many :doodads, :singular => :doodad,
                                      :named => true
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
              Olfactory.build :widget do |t|
                t.doodad :a, :shiny
              end
            end
            it do
              # Expect it to invoke a preset on the subtemplate
              expect(subject[:doodads]).to eq({ :a => { :gizmo => "shiny #{value}" }})
            end
          end
          context "that does not match a defined preset" do
            subject do
              Olfactory.build :widget do |t|
                t.doodad :a, :rusty
              end
            end
            it do
              # Expect it to invoke a preset on the subtemplate
              expect{ subject }.to raise_error
            end
          end
        end
        context "given a name & block value" do
          subject do
            Olfactory.build :widget do |t|
              t.doodad :a do |d|
                d.gizmo value
              end
            end
          end
          it do
            expect(subject[:doodads]).to eq({ :a => { :gizmo => value }})
          end
        end
        context "given a no name" do
          subject do
            Olfactory.build :widget do |t|
              t.doodad
            end
          end
          it do
            expect { subject }.to raise_error
          end
        end
        context "given a no name & numeric value" do
          subject do
            Olfactory.build :widget do |t|
              t.doodad 1
            end
          end
          it do
            expect(subject[:doodads]).to eq({ 1 => {} })
          end
        end
      end
      context "invoked as plural" do
        context "given a hash value" do
          subject do
            Olfactory.build :widget do |t|
              t.doodads :a => value
            end
          end
          it do
            expect(subject[:doodads]).to eq(nil)
          end
        end
      end
    end
    context "with template name" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.embeds_many :doodads, :singular => :doodad,
                                  :template => :thingamabob
        end
        Olfactory.template :thingamabob do |t|
          t.has_one :gizmo
        end
      end
      context "given no value" do
        subject do
          Olfactory.build :widget do |t|
            t.doodad
          end
        end
        it do
          expect(subject[:doodads]).to eq([{}])
        end
      end
    end
  end
  context "sequence" do
    context "with a scope" do
      context "bound to the template" do
        context do
          before(:example) do
            Olfactory.template :building do |t|
              t.has_one :address
              t.sequence :address, :scope => :template do |n, options|
                "#{(2*n) + 2} #{"#{options[:prefix]} " if options[:prefix]}BROADWAY"
              end
            end
          end
          context "given nothing" do
            subject do
              Olfactory.build :building do |building|
                building.address building.generate(:address)
              end
            end
            it { expect(subject[:address]).to eq("2 BROADWAY") }
          end
          context "given options" do
            subject do
              Olfactory.build :building do |building|
                building.address building.generate(:address, :prefix => "WEST")
              end
            end
            it { expect(subject[:address]).to eq("2 WEST BROADWAY") }
          end
          context "given a block" do
            subject do
              Olfactory.build :building do |building|
                building.address do
                  building.generate(:address) do |n|
                    "#{(2*n) + 2} JOHN STREET"
                  end
                end
              end
            end
            it { expect(subject[:address]).to eq("2 JOHN STREET") }
          end
          context "given options and a block" do
            subject do
              Olfactory.build :building do |building|
                building.address do
                  building.generate(:address, :suffix => "ROAD") do |n, options|
                    "#{(2*n) + 2} JOHN#{options[:suffix] ? " #{options[:suffix]}" : " STREET"}"
                  end
                end
              end
            end
            it { expect(subject[:address]).to eq("2 JOHN ROAD") }
          end
          context "given a dimension" do
            let!(:building_one) do
              Olfactory.build :building do |building|
                building.address building.generate(:address)
              end
            end
            let!(:building_two) do
              Olfactory.build :building do |building|
                building.address building.generate(:address, :dimension => "LAS VEGAS")
              end
            end
            let!(:building_three) do
              Olfactory.build :building do |building|
                building.address building.generate(:address)
              end
            end
            it { expect(building_one[:address]).to eq("2 BROADWAY") }
            it { expect(building_two[:address]).to eq("2 BROADWAY") }
            it { expect(building_three[:address]).to eq("4 BROADWAY") }
          end
        end
        context "given sequential invocations" do
          before(:context) do
            Olfactory.template :building do |t|
              t.has_one :address
              t.sequence :address, :scope => :template do |n, options|
                "#{(2*n) + 2} #{"#{options[:prefix]} " if options[:prefix]}BROADWAY"
              end
            end
          end
          let(:building_one) do
            Olfactory.build :building do |building|
              building.address { building.generate(:address) }
            end
          end
          it { expect(building_one[:address]).to eq("2 BROADWAY") }
          let(:building_two) do
            Olfactory.build :building do |building|
              building.address { building.generate(:address) }
            end
          end
          it { expect(building_two[:address]).to eq("4 BROADWAY") }
        end
      end
      context "bound to the instance" do
        context do
          before(:example) do
            Olfactory.template :building do |t|
              t.has_one :address
              t.sequence :address, :scope => :instance do |n, options|
                "#{(2*n) + 2} #{"#{options[:prefix]} " if options[:prefix]}BROADWAY"
              end
            end
          end
          context "given nothing" do
            subject do
              Olfactory.build :building do |building|
                building.address building.generate(:address)
              end
            end
            it { expect(subject[:address]).to eq("2 BROADWAY") }
          end
          context "given options" do
            subject do
              Olfactory.build :building do |building|
                building.address building.generate(:address, :prefix => "WEST")
              end
            end
            it { expect(subject[:address]).to eq("2 WEST BROADWAY") }
          end
          context "given a block" do
            subject do
              Olfactory.build :building do |building|
                building.address do
                  building.generate(:address) do |n|
                    "#{(2*n) + 2} JOHN STREET"
                  end
                end
              end
            end
            it { expect(subject[:address]).to eq("2 JOHN STREET") }
          end
          context "given options and a block" do
            subject do
              Olfactory.build :building do |building|
                building.address do
                  building.generate(:address, :suffix => "ROAD") do |n, options|
                    "#{(2*n) + 2} JOHN#{options[:suffix] ? " #{options[:suffix]}" : " STREET"}"
                  end
                end
              end
            end
            it { expect(subject[:address]).to eq("2 JOHN ROAD") }
          end
          context "given a dimension" do
            before(:example) do
              Olfactory.template :building do |t|
                t.has_one :address
                t.has_one :other_address
                t.has_one :another_address
                t.sequence :address, :scope => :instance do |n, options|
                  "#{(2*n) + 2} #{"#{options[:prefix]} " if options[:prefix]}BROADWAY"
                end
              end
            end
            let!(:building_one) do
              Olfactory.build :building do |building|
                building.address building.generate(:address)
                building.other_address building.generate(:address, :dimension => "LAS VEGAS")
                building.another_address building.generate(:address)
              end
            end
            let!(:building_two) do
              Olfactory.build :building do |building|
                building.address building.generate(:address)
                building.other_address building.generate(:address, :dimension => "LAS VEGAS")
                building.another_address building.generate(:address)
              end
            end
            it { expect(building_one[:address]).to eq("2 BROADWAY") }
            it { expect(building_one[:other_address]).to eq("2 BROADWAY") }
            it { expect(building_one[:another_address]).to eq("4 BROADWAY") }
            it { expect(building_two[:address]).to eq("2 BROADWAY") }
            it { expect(building_two[:other_address]).to eq("2 BROADWAY") }
            it { expect(building_two[:another_address]).to eq("4 BROADWAY") }
          end
        end
        context "given sequential invocations" do
          before(:context) do
            Olfactory.template :building do |t|
              t.has_one :address
              t.has_one :other_address
              t.sequence :address, :scope => :instance do |n, options|
                "#{(2*n) + 2} #{"#{options[:prefix]} " if options[:prefix]}BROADWAY"
              end
            end
          end
          let(:building_one) do
            Olfactory.build :building do |building|
              building.address building.generate(:address)
              building.other_address building.generate(:address)
            end
          end
          it { expect(building_one[:address]).to eq("2 BROADWAY") }
          it { expect(building_one[:other_address]).to eq("4 BROADWAY") }
          let(:building_two) do
            Olfactory.build :building do |building|
              building.address building.generate(:address)
              building.other_address building.generate(:address)
            end
          end
          it { expect(building_two[:address]).to eq("2 BROADWAY") }
          it { expect(building_two[:other_address]).to eq("4 BROADWAY") }
        end
      end
    end
    context "after being invoked" do
      before(:context) do
        Olfactory.template :numbers do |t|
          t.has_one :even_count
          t.has_one :odd_count
          t.sequence :even, :scope => :template do |n|
            (2*n) + 2
          end
          t.sequence :odd, :scope => :template do |n|
            (2*n) + 1
          end
        end
      end
      let(:first_set) do
        Olfactory.build :numbers do |n|
          n.even_count n.generate(:even)
          n.even_count n.generate(:even)
          n.odd_count n.generate(:odd)
          n.odd_count n.generate(:odd)
        end
      end
      it do
        expect(first_set[:even_count]).to eq(4)
        expect(first_set[:odd_count]).to eq(3)
      end
      context "and called to reset" do
        before(:context) do
          Olfactory.reset_template_sequences(:numbers)
        end
        let(:second_set) do
          Olfactory.build :numbers do |n|
            n.even_count n.generate(:even)
            n.even_count n.generate(:even)
            n.odd_count n.generate(:odd)
            n.odd_count n.generate(:odd)
          end
        end
        it do
          expect(second_set[:even_count]).to eq(4)
          expect(second_set[:odd_count]).to eq(3)
        end
      end
    end
  end
  context "dictionary" do
    context "with a scope" do
      context "bound to the template" do
        context do
          before(:context) do
            Olfactory.template :address do |t|
              t.has_one :street_code
              t.dictionary :street_codes, :scope => :template
            end
          end
          subject do
            Olfactory.build :address do |address|
              address.street_code do
                address.street_codes["BROADWAY"] ||= 10001
              end
            end
          end
          it { expect(subject[:street_code]).to eq(10001) }
        end
        context "given sequential invocations" do
          before(:context) do
            Olfactory.template :address do |t|
              t.has_one :street_code
              t.dictionary :street_codes, :scope => :template
              t.sequence :street_code, :scope => :template, :seed => 1 do |n|
                (10000 + n)
              end
            end
          end
          let!(:address_one) do
            Olfactory.build :address do |address|
              address.street_code { address.street_codes["BROADWAY"] ||= address.generate(:street_code) }
            end
          end
          let!(:address_two) do
            Olfactory.build :address do |address|
              address.street_code { address.street_codes["BROADWAY"] ||= address.generate(:street_code) }
            end
          end
          let!(:address_three) do
            Olfactory.build :address do |address|
              address.street_code { address.street_codes["JOHN STREET"] ||= address.generate(:street_code) }
            end
          end

          it { expect(address_one[:street_code]).to eq(10001) }
          it { expect(address_two[:street_code]).to eq(10001) }
          it { expect(address_three[:street_code]).to eq(10002) }
        end
      end
      context "bound to the instance" do
        context do
          before(:context) do
            Olfactory.template :address do |t|
              t.has_one :street_code
              t.has_one :other_street_code
              t.has_one :another_street_code
              t.dictionary :street_codes, :scope => :instance
            end
          end
          subject do
            Olfactory.build :address do |address|
              address.street_code { address.street_codes["BROADWAY"] ||= 10001 }
              address.other_street_code { address.street_codes["BROADWAY"] ||= 10002 }
              address.another_street_code { address.street_codes["JOHN STREET"] ||= 10003 }
            end
          end
          it { expect(subject[:street_code]).to eq(10001) }
          it { expect(subject[:other_street_code]).to eq(10001) }
          it { expect(subject[:another_street_code]).to eq(10003) }
        end
        context "given sequential invocations" do
          before(:context) do
            Olfactory.template :address do |t|
              t.has_one :street_code
              t.has_one :other_street_code
              t.has_one :another_street_code
              t.dictionary :street_codes, :scope => :instance
              t.sequence :street_code, :scope => :instance, :seed => 1 do |n|
                (10000 + n)
              end
            end
          end
          let!(:address_one) do
            Olfactory.build :address do |address|
              address.street_code { address.street_codes["BROADWAY"] ||= address.generate(:street_code) }
              address.other_street_code { address.street_codes["BROADWAY"] ||= address.generate(:street_code) }
              address.another_street_code { address.street_codes["JOHN STREET"] ||= address.generate(:street_code) }
            end
          end
          let!(:address_two) do
            Olfactory.build :address do |address|
              address.street_code { address.street_codes["BROADWAY"] ||= address.generate(:street_code) }
              address.other_street_code { address.street_codes["BROADWAY"] ||= address.generate(:street_code) }
              address.another_street_code { address.street_codes["JOHN STREET"] ||= address.generate(:street_code) }
            end
          end
          it { expect(address_one[:street_code]).to eq(10001) }
          it { expect(address_one[:other_street_code]).to eq(10001) }
          it { expect(address_one[:another_street_code]).to eq(10002) }
          it { expect(address_two[:street_code]).to eq(10001) }
          it { expect(address_two[:other_street_code]).to eq(10001) }
          it { expect(address_two[:another_street_code]).to eq(10002) }
        end
      end
    end
    context "after being invoked" do
      before(:context) do
        Olfactory.template :stuff do |t|
          t.has_one :widget
          t.has_one :another_widget
          t.has_one :doodad
          t.has_one :another_doodad
          t.dictionary :widget_catalog, :scope => :template
          t.dictionary :doodad_catalog, :scope => :template
        end
      end
      let(:first_set) do
        Olfactory.build :stuff do |n|
          n.widget do
            if n.widget_catalog["Widget"]
              "Existing widget!"
            else
              n.widget_catalog["Widget"] = "New widget!"
            end
          end
          n.another_widget do
            if n.widget_catalog["Widget"]
              "Existing widget!"
            else
              n.widget_catalog["Widget"] = "New widget!"
            end
          end
          n.doodad do
            if n.doodad_catalog["Doodad"]
              "Existing doodad!"
            else
              n.doodad_catalog["Doodad"] = "New doodad!"
            end
          end
          n.another_doodad do
            if n.doodad_catalog["Doodad"]
              "Existing doodad!"
            else
              n.doodad_catalog["Doodad"] = "New doodad!"
            end
          end
        end
      end
      it do
        expect(first_set[:widget]).to eq("New widget!")
        expect(first_set[:another_widget]).to eq("Existing widget!")
        expect(first_set[:doodad]).to eq("New doodad!")
        expect(first_set[:another_doodad]).to eq("Existing doodad!")
      end
      context "and called to reset" do
        before(:context) do
          Olfactory.reset_template_dictionaries(:stuff)
        end
        let(:second_set) do
          Olfactory.build :stuff do |n|
            n.widget do
              if n.widget_catalog["Widget"]
                "Existing widget!"
              else
                n.widget_catalog["Widget"] = "New widget!"
              end
            end
            n.another_widget do
              if n.widget_catalog["Widget"]
                "Existing widget!"
              else
                n.widget_catalog["Widget"] = "New widget!"
              end
            end
            n.doodad do
              if n.doodad_catalog["Doodad"]
                "Existing doodad!"
              else
                n.doodad_catalog["Doodad"] = "New doodad!"
              end
            end
            n.another_doodad do
              if n.doodad_catalog["Doodad"]
                "Existing doodad!"
              else
                n.doodad_catalog["Doodad"] = "New doodad!"
              end
            end
          end
        end
        it do
          expect(second_set[:widget]).to eq("New widget!")
          expect(second_set[:another_widget]).to eq("Existing widget!")
          expect(second_set[:doodad]).to eq("New doodad!")
          expect(second_set[:another_doodad]).to eq("Existing doodad!")
        end
      end
    end
  end
  context "macros" do
    before(:context) do
      Olfactory.template :widget do |t|
        t.has_one :doodad
        t.macro :make_shiny do |m, v|
          m.doodad "shiny #{m[:doodad]}"
        end
      end
    end
    let(:value) { "doodad" }

    subject do
      Olfactory.build :widget do |t|
        t.doodad value
        t.make_shiny
      end
    end
    it "should execute its block" do
      expect(subject[:doodad]).to eq("shiny #{value}")
    end

    context "with parameters" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.has_one :doodad
          t.macro :make do |m, adj, adj2|
            m.doodad "#{adj.to_s} #{adj2.to_s} #{m[:doodad]}"
          end
        end
      end
      subject do
        Olfactory.build :widget do |t|
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
    before(:context) do
      Olfactory.template :widget do |t|
        t.has_one :doodad
      end
    end
    let(:value) { "temporary value"}
    context "when set" do
      context "given a basic value" do
        subject do
          Olfactory.build :widget do |t|
            t.transient :foo, value
          end
        end
        it do
          expect(subject.transients[:foo]).to eq(value)
        end
      end
      context "given a block" do
        subject do
          Olfactory.build :widget do |t|
            t.transient :foo do
              value
            end
          end
        end
        it do
          expect(subject.transients[:foo]).to eq(value)
        end
      end
    end
    context "when read" do
      subject do
        Olfactory.build :widget do |t|
          t.transient :foo, value
          t.doodad "#{t.transients[:foo]}"
        end
      end
      it do
        expect(subject[:doodad]).to eq(value)
      end
    end
    context "when inherited" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.embeds_one :doodad
        end
        Olfactory.template :doodad do |t|
          t.has_one :gizmo
        end
      end
      subject do
        Olfactory.build :widget do |t|
          t.transient :foo, value
          t.doodad
        end
      end
      it do
        expect(subject[:doodad].transients[:foo]).to eq(value)
      end
    end
  end
  context "defaults" do
    let(:value) { "doodad" }
    let(:default_value) { "default doodad" }
    let(:default_after_value) { "default after doodad" }
    context "before" do
      context "all" do
        before(:context) do
          Olfactory.template :widget do |t|
            t.has_one :doodad
            t.has_one :other_doodad
            t.before do |d|
              d.doodad default_value
              d.other_doodad default_value
            end
          end
        end
        subject do
          Olfactory.build :widget do |t|
            t.doodad value
          end
        end
        it "values can be overriden" do
          expect(subject[:doodad]).to eq(value)
        end
        it "values can be set"do
          expect(subject[:other_doodad]).to eq(default_value)
        end
      end
      context "embedded" do
        before(:context) do
          Olfactory.template :widget do |t|
            t.embeds_one :doodad
            t.macro :quality do |m, type|
              m.transient :attribute, type.to_s
            end
            t.before(:embedded) do |d|
              d.quality :dull
            end
            t.before do |d|
              d.quality :scratched
            end
          end
          Olfactory.template :doodad do |t|
            t.has_one :gizmo
            t.after do |d|
              d.gizmo "#{d.transients[:attribute]} #{value}"
            end
          end
        end
        let(:shiny) do
          Olfactory.build :widget do |w|
            w.quality :shiny
            w.doodad
          end
        end
        let(:dull) do
          Olfactory.build :widget do |w|
            w.doodad
          end
        end
        it { expect(shiny[:doodad][:gizmo]).to eq("shiny #{value}")}
        it { expect(dull[:doodad][:gizmo]).to eq("dull #{value}")}
        context "(run once)" do
          before(:context) do
            Olfactory.template :widget do |t|
              t.embeds_many :doodads, :singular => :doodad
              t.has_one :thingamabob
              t.macro :quality do |m, type|
                m.transient :attribute, type.to_s
              end
              t.before(:embedded, :run => :once) do |d|
                d.quality :dull
                d.thingamabob "thingamabob" if d[:doodads] && d[:doodads].count > 0
              end
            end
            Olfactory.template :doodad do |t|
              t.has_one :gizmo
              t.after do |d|
                d.gizmo "#{d.transients[:attribute]} #{value}"
              end
            end
          end
          subject do
            Olfactory.build :widget do |w|
              w.doodad
              w.quality :shiny
              w.doodad
            end
          end
          it do
            expect(subject[:doodads]).to eq([{ :gizmo => "dull #{value}" }, { :gizmo => "shiny #{value}" }])
            expect(subject[:thingamabob]).to be_nil
          end
        end
      end
    end
    context "after" do
      context "values" do
        context "given a has_one" do
          before(:context) do
            Olfactory.template :widget do |t|
              t.has_one :doodad
              t.has_one :other_doodad
              t.after do |d|
                d.doodad default_value
                d.other_doodad default_value
              end
            end
          end
          subject do
            Olfactory.build :widget do |t|
              t.doodad value
            end
          end
          it "will not override existing ones" do
            expect(subject[:doodad]).to eq(value)
          end
          it "will fill in missing ones"do
            expect(subject[:other_doodad]).to eq(default_value)
          end
        end
        context "given a has_many" do
          before(:context) do
            Olfactory.template :widget do |t|
              t.has_many :doodads, :singular => :doodad
              t.has_many :other_doodads, :singular => :other_doodad
              t.after do |d|
                d.doodad default_value
                d.doodads default_value
                d.other_doodad default_value
                d.other_doodads default_value, default_value
              end
            end
          end
          subject do
            Olfactory.build :widget do |t|
              t.doodad value
            end
          end
          it "will not override existing ones" do
            expect(subject[:doodads]).to eq([value])
          end
          it "will fill in missing ones"do
            expect(subject[:other_doodads]).to eq([default_value, default_value, default_value])
          end
        end
        context "given a embeds_one" do
          before(:context) do
            Olfactory.template :widget do |t|
              t.embeds_one :doodad
              t.embeds_one :other_doodad
              t.after do |d|
                d.doodad { |doodad| doodad.gizmo default_value }
                d.other_doodad { |doodad| doodad.gizmo default_value }
              end
            end
            Olfactory.template :doodad do |t|
              t.has_one :gizmo
            end
            Olfactory.template :other_doodad do |t|
              t.has_one :gizmo
            end
          end
          subject do
            Olfactory.build :widget do |t|
              t.doodad { |doodad| doodad.gizmo value }
            end
          end
          it "will not override existing ones" do
            expect(subject[:doodad]).to eq({ :gizmo => value })
          end
          it "will fill in missing ones" do
            expect(subject[:other_doodad]).to eq({ :gizmo => default_value })
          end
        end
        context "given a embeds_many" do
          before(:context) do
            Olfactory.template :widget do |t|
              t.embeds_many :doodads, :singular => :doodad
              t.embeds_many :other_doodads, :singular => :other_doodad
              t.after do |d|
                d.doodad { |doodad| doodad.gizmo default_value }
                d.doodads 2 do |doodad| doodad.gizmo default_value end
                d.other_doodad { |doodad| doodad.gizmo default_value }
                d.other_doodads 2 do |doodad| doodad.gizmo default_value end
              end
            end
            Olfactory.template :doodad do |t|
              t.has_one :gizmo
            end
            Olfactory.template :other_doodad do |t|
              t.has_one :gizmo
            end
          end
          subject do
            Olfactory.build :widget do |t|
              t.doodad { |doodad| doodad.gizmo value }
            end
          end
          it "will not override existing ones" do
            expect(subject[:doodads]).to eq([{ :gizmo => value }])
          end
          it "will fill in missing ones"do
            expect(subject[:other_doodads]).to eq([{ :gizmo => default_value }, { :gizmo => default_value }, { :gizmo => default_value }])
          end
        end
      end
    end
    context "both before and after" do
      context "given no value" do
        before(:context) do
          Olfactory.template :widget do |t|
            t.has_one :doodad
            t.before do |d|
              d.doodad default_value
            end
            t.after do |d|
              d.doodad default_after_value
            end
          end
        end
        subject do
          Olfactory.build :widget
        end
        it "will override with a default the second time" do
          expect(subject[:doodad]).to eq(default_after_value)
        end
      end
      context "given a value" do
        before(:context) do
          Olfactory.template :widget do |t|
            t.has_one :doodad
            t.before do |d|
              d.doodad default_value
            end
            t.after do |d|
              d.doodad default_value
            end
          end
        end
        subject do
          Olfactory.build :widget do |t|
            t.doodad value
          end
        end
        it "will not set override with a default the second time" do
          expect(subject[:doodad]).to eq(value)
        end
      end
    end
  end
  context "instantiators" do
    context "given a symbol and block" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.has_one :doodad
          t.instantiate :doodad do |i|
            SaveableString.new("#{i[:doodad]}-instance")
          end
        end
      end
      let(:value) { "doodad" }
      let(:template) { Olfactory.build :widget do |w| w.doodad "doodad" end }

      context "invoked with #build" do
        subject do
          template.build(:doodad)
        end
        it do
          expect(subject).to eq("#{value}-instance")
          expect(subject.saved?).to be false
        end
      end
      context "invoked with #create" do
        subject do
          template.create(:doodad)
        end
        context "that returns a saveable object" do
          before(:context) do
            Olfactory.template :widget do |t|
              t.has_one :doodad
              t.instantiate :doodad do |i|
                SaveableString.new("#{i[:doodad]}-instance")
              end
            end
          end
          it do
            expect(subject).to eq("#{value}-instance")
            expect(subject.saved?).to be true
          end
        end
        context "that returns an array of saveable objects" do
          before(:context) do
            Olfactory.template :widget do |t|
              t.has_one :doodad
              t.instantiate :doodad do |i|
                [SaveableString.new("#{i[:doodad]}-instance-1"), SaveableString.new("#{i[:doodad]}-instance-2")]
              end
            end
          end
          it do
            expect(subject).to eq(["#{value}-instance-1", "#{value}-instance-2"])
            expect(subject.all? { |d| d.saved? }).to be true
          end
        end
        context "that returns a hash of saveable objects" do
          before(:context) do
            Olfactory.template :widget do |t|
              t.has_one :doodad
              t.instantiate :doodad do |i|
                { 1 => SaveableString.new("#{i[:doodad]}-instance"), 2 => SaveableString.new("#{i[:doodad]}-instance") }
              end
            end
          end
          it do
            expect(subject).to eq({ 1 => "#{value}-instance", 2 => "#{value}-instance" })
            expect(subject.values.all? { |d| d.saved? }).to be true
          end
        end
      end
    end
  end
  context "when created" do
    let(:value) { "saveable string" }
    context "containing a saveable object" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.has_one :doodad
        end
      end
      
      subject do
        Olfactory.create :widget do |w|
          w.doodad SaveableString.new(value)
        end
      end
      it do
        expect(subject[:doodad].saved?).to be true
      end
    end
    context "containing a generic collection of saveable objects" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.has_many :doodads
        end
      end
      subject do
        Olfactory.create :widget do |w|
          w.doodads SaveableString.new(value), SaveableString.new(value)
        end
      end
      it { expect(subject[:doodads].first.saved?).to be true }
      it { expect(subject[:doodads].last.saved?).to be true }
    end
    context "containing a named collection of saveable objects" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.has_many :doodads, :named => true
        end
      end
      subject do
        Olfactory.create :widget do |w|
          w.doodads :a => SaveableString.new(value), :b => SaveableString.new(value)
        end
      end
      it { expect(subject[:doodads][:a].saved?).to be true }
      it { expect(subject[:doodads][:b].saved?).to be true }
    end
    context "with an embedded template" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.embeds_one :doodad
        end
      end
      context "containing a saveable object" do
        before(:context) do
          Olfactory.template :doodad do |t|
            t.has_one :gizmo
          end
        end
        subject do
          Olfactory.create :widget do |w|
            w.doodad { |d| d.gizmo SaveableString.new(value) }
          end
        end
        it { expect(subject[:doodad][:gizmo].saved?).to be true }
      end
      context "containing a generic collection of saveable objects" do
        before(:context) do
          Olfactory.template :doodad do |t|
            t.has_many :gizmos
          end
        end
        subject do
          Olfactory.create :widget do |w|
            w.doodad { |d| d.gizmos SaveableString.new(value), SaveableString.new(value) }
          end
        end
        it { expect(subject[:doodad][:gizmos].first.saved?).to be true }
        it { expect(subject[:doodad][:gizmos].last.saved?).to be true }
      end
      context "containing a named collection of saveable objects" do
        before(:context) do
          Olfactory.template :doodad do |t|
            t.has_many :gizmos, :named => true
          end
        end
        subject do
          Olfactory.create :widget do |w|
            w.doodad { |d| d.gizmos :a => SaveableString.new(value), :b => SaveableString.new(value) }
          end
        end
        it { expect(subject[:doodad][:gizmos][:a].saved?).to be true }
        it { expect(subject[:doodad][:gizmos][:b].saved?).to be true }
      end
    end
    context "with a generic collection of embedded templates" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.embeds_many :doodads, :singular => :doodad
        end
      end
      context "containing a saveable object" do
        before(:context) do
          Olfactory.template :doodad do |t|
            t.has_one :gizmo
          end
        end
        subject do
          Olfactory.create :widget do |w|
            w.doodad { |d| d.gizmo SaveableString.new(value) }
          end
        end
        it { expect(subject[:doodads].first[:gizmo].saved?).to be true }
      end
      context "containing a generic collection of saveable objects" do
        before(:context) do
          Olfactory.template :doodad do |t|
            t.has_many :gizmos
          end
        end
        subject do
          Olfactory.create :widget do |w|
            w.doodad { |d| d.gizmos SaveableString.new(value), SaveableString.new(value) }
          end
        end
        it { expect(subject[:doodads].first[:gizmos].first.saved?).to be true }
        it { expect(subject[:doodads].first[:gizmos].last.saved?).to be true }
      end
      context "containing a named collection of saveable objects" do
        before(:context) do
          Olfactory.template :doodad do |t|
            t.has_many :gizmos, :named => true
          end
        end
        subject do
          Olfactory.create :widget do |w|
            w.doodad { |d| d.gizmos :a => SaveableString.new(value), :b => SaveableString.new(value) }
          end
        end
        it { expect(subject[:doodads].first[:gizmos][:a].saved?).to be true }
        it { expect(subject[:doodads].first[:gizmos][:b].saved?).to be true }
      end
    end
    context "with a named collection of embedded templates" do
      before(:context) do
        Olfactory.template :widget do |t|
          t.embeds_many :doodads, :singular => :doodad, :named => true
        end
      end
      context "containing a saveable object" do
        before(:context) do
          Olfactory.template :doodad do |t|
            t.has_one :gizmo
          end
        end
        subject do
          Olfactory.create :widget do |w|
            w.doodad :one do |d|
              d.gizmo SaveableString.new(value)
            end
          end
        end
        it { expect(subject[:doodads][:one][:gizmo].saved?).to be true }
      end
      context "containing a generic collection of saveable objects" do
        before(:context) do
          Olfactory.template :doodad do |t|
            t.has_many :gizmos
          end
        end
        subject do
          Olfactory.create :widget do |w|
            w.doodad :one do |d|
              d.gizmos SaveableString.new(value), SaveableString.new(value)
            end
          end
        end
        it { expect(subject[:doodads][:one][:gizmos].first.saved?).to be true }
        it { expect(subject[:doodads][:one][:gizmos].last.saved?).to be true }
      end
      context "containing a named collection of saveable objects" do
        before(:context) do
          Olfactory.template :doodad do |t|
            t.has_many :gizmos, :named => true
          end
        end
        subject do
          Olfactory.create :widget do |w|
            w.doodad :one do |d|
              d.gizmos :a => SaveableString.new(value), :b => SaveableString.new(value)
            end
          end
        end
        it { expect(subject[:doodads][:one][:gizmos][:a].saved?).to be true }
        it { expect(subject[:doodads][:one][:gizmos][:b].saved?).to be true }
      end
    end
  end
end


