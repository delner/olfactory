Olfactory
==========

### Introduction

Olfactory is a factory extension for creating complex object sets, as a supplement to *factory_girl*, *fabrication*, or other factories.

It introduces the concept of **templates**: an abstract group of objects. These can be used to make test setup much quicker and easier.

Templates are not intended to replace most factories, but supplement them. They are most useful when:
 - Subjects are weakly related or non-relational (e.g. not joined by ActiveRecord associations)
 - You require a collection of objects that are not directly related (or easily built using factories)
 - You'd prefer short-hand notation, or to abstract Factory implementation out of your tests
   - e.g. Define a set of generic factories other programmers can use, without requiring them to understand the underlying details

For example, given:
```ruby
context "networkable people" do
  let(:phone_user) { create(:person, :devices => [phone]) }
  let(:phone) { create(:android, apps => [facebook_app_one, twitter_app_one]) } # Factory(:device)
  let(:facebook_phone) { create(:facebook, :platform => :phone) } # Factory(:app)
  let(:twitter_phone) { create(:twitter, :platform => :phone) } # Factory(:app)
  
  let(:tablet_user) { create(:person, :devices => [tablet]) }
  let(:tablet) { create(:tablet, apps => [facebook_tablet]) }  # Factory(:device)
  let(:facebook_tablet) { create(:facebook, :platform => :tablet) }  # Factory(:app)
  
  let(:desktop_user) { create(:person, :devices => [desktop]) }
  let(:desktop) { create(:desktop, apps => [twitter_desktop]) }  # Factory(:device)
  let(:twitter_desktop) { create(:twitter, :platform => :desktop) }  # Factory(:app)
  
  it { expect(phone_user.can_network_with(tablet_user, desktop_user).to be_true }
end
```

This is a lot of setup for a simple test case. We could write a bunch of named factories, but then the test logic simply ends up in a factory file rather than our test; not good.

Instead, we can use templates to simplify our definitions:
```ruby
context "networkable people" do
  let(:user_group) do
    Olfactory.create_template :user_group do |group|
      group.user :desktop_user { |user| user.phone { |phone| phone.apps :facebook, :twitter } }
      group.user :tablet_user { |user| user.tablet { |tablet| tablet.app :facebook } }
      group.user :phone_user { |user| user.desktop { |desktop| desktop.app :twitter } }
    end
  end
  subject { user_group[:users] }
  it { expect(subject[:desktop_user].can_network_with(subject[:tablet_user], subject[:phone_user]).to be_true }
end
```

### Usage

##### Defining templates

Templates are defined in `spec/templates/**/*.rb` files. Define a template using the `Olfactory#template` method.

    Olfactory.template :computer do |t|
      ...
    end

##### #has_one

Defines a placeholder for field containing a single object.

Definition:
> .has_one :name [, :alias => :alias_name]

When using:
> .name|alias_name object|&block

Sample:

    # Template definition
    Olfactory.template :computer do |t|
      t.has_one :keyboard
      t.has_one :cpu
    end
    # Build instance of template
    Olfactory.build_template :computer do |c|
      c.keyboard "X4 Sidewinder"
      c.cpu { FactoryGirl::build(:cpu) }
    end
    # Result
    {
      :keyboard => "X4 Sidewinder",
      :cpu => <Cpu>
    }
    
Specify an alias using `:alias => <name>`:

    # Template definition
    Olfactory.template :computer do |t|
      t.has_one :cpu, :alias => :processor
    end
    # Build instance of template
    Olfactory.build_template :computer do |c|
      c.processor "Intel Xeon"
    end
    # Result
    {
      :cpu => "Intel Xeon"
    }

##### #has_many

Defines a placeholder for a collection of objects. Each invocation appends the resulting items to the collection.

Definition:
> has_many :name [, :alias => :alias_name,
>                   :singular => :singular_name,
>                   :named => true|false]

When using:
> name|alias_name|singular_name [object|&block|(quantity &block)]

Sample:

    # Template definition
    Olfactory.template :computer do |t|
      t.has_many :cpu
      t.has_many :memory_sticks, :singular => :memory_stick
      t.has_many :drives, :named => true
      t.has_many :usb_ports
    end
    # Build instance of template
    Olfactory.build_template :computer do |c|
      c.cpu "Intel i7"
      c.cpu "Onboard graphics"
      c.memory_stick "2GB"
      c.memory_stick "2GB"
      c.drives :ssd "Seagate"
      c.drives :optical "Memorex"
      c.usb_ports 3 do
        "2.0"
      end
      c.usb_ports 3 do
        "3.0"
      end
    end
    # Result
    {
      :cpu => ["Intel i7", "Onboard graphics"],
      :memory_sticks => ["2GB", "2GB"],
      :drives => {
        :ssd => "Seagate",
        :optical => "Memorex"
      },
      :usb_ports => ["2.0", "2.0", "2.0", "3.0", "3.0", "3.0"]
    }
    
- `:singular` works exactly the same as an alias (in a future update, this will only append a single object to the collection.)
- `:named` converts the collection to a `Hash`. When true, all invocations must provide a name (first argument.)
- Invoking with an integer value and a block will enumerate the result of that block N times, and add it to the collection.
    
##### #embeds_one

Defines a placeholder for an embedded template using `#embeds_one`:

    Olfactory.template :computer do |t|
      t.embeds_one :cpu
    end
    Olfactory.template :cpu do |t|
      t.has_many :cpu_core
    end

Creates:

    {
      :cpu => {
                :cpu_core => [(Some object...), (Some object...)]
              }
    }
    
##### #embeds_many

Defines a placeholder for an embedded template collection using `#embeds_many`:

    Olfactory.template :computer do |t|
      t.embeds_many :cpu
    end
    Olfactory.template :cpu do |t|
      t.has_one :cpu_core
    end

Creates:

    {
      :cpu => [{
                :cpu_core => (Some object...)
              },
              {
                :cpu_core => (Some object...)
              }]
    }

##### #preset

Defines a preset of values:

    Olfactory.template :computer do |t|
      t.embeds_many :cpu
      t.preset :dual_core do |p|
        p.cpu 2
      end
    end
    Olfactory.template :cpu do |t|
      t.has_one :cpu_core
    end
    
Invoking `Olfactory.build_template :computer, preset: :dual_core` creates:

    {
      :cpu => [{
                :cpu_core => (Some object...)
              },
              {
                :cpu_core => (Some object...)
              }]
    }
    
##### #default

Defines default values, which are used to fill in any empty `has`, `embeds` or `transient` fields:

    Olfactory.template :computer do |t|
      t.embeds_many :cpu
      t.default do |d|
        d.cpu 1
      end
    end
    Olfactory.template :cpu do |t|
      t.has_one :cpu_core
      t.default do |d|
        d.cpu_core "Computer core"
      end
    end

Invoking `Olfactory.build_template :computer` creates:

    {
      :cpu => [{
                :cpu_core => "Computer core"
              }]
    }

##### Building templates

Build a set of objects from a template using `Olfactory#build_template`:

    Olfactory.build_template :computer
