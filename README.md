Olfactory
==========

[![Build Status](https://travis-ci.org/delner/olfactory.svg?branch=master)](https://travis-ci.org/delner/olfactory) ![Gem Version](https://img.shields.io/gem/v/olfactory.svg?maxAge=2592000)
###### *For Ruby 2+*

### Introduction

Olfactory is a factory extension for creating complex object sets, as a supplement to `factory_girl`, `fabrication`, or other factories.

It introduces the concept of **templates**: a group of named values/objects (as a `Hash`.) You define what objects (or other templates) your template can contain (similar to a factory), then you can create instances of that template using the `#build` or `#create` functions. These templates can be used to make test setup much quicker and easier. Templates are not intended to replace factories, but bridge the gap where `factory_girl` and `fabrication` factories fall short.

They are most useful when:
 - Your models are weakly related or non-relational (e.g. not joined by ActiveRecord associations)
 - You require a collection of objects that are not directly related (or easily built using factories & associations)
 - You'd prefer short-hand notation
 - You'd like to abstract Factory implementation out of your tests
   - e.g. Define a set of generic factories other programmers can use, without requiring them to understand the underlying class or relational structure.

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

Instead, we can use templates to define shorthand notation:
```ruby
context "networkable people" do
  let(:user_group) do
    Olfactory.create :user_group do |group|
      group.user :desktop_user { |user| user.phone { |phone| phone.apps :facebook, :twitter } }
      group.user :tablet_user { |user| user.tablet { |tablet| tablet.app :facebook } }
      group.user :phone_user { |user| user.desktop { |desktop| desktop.app :twitter } }
    end
  end
  subject { user_group[:users] }
  it { expect(subject[:desktop_user].can_network_with(subject[:tablet_user], subject[:phone_user]).to be_true }
end
```

In this sample, the `let(:user_group)` block returns a `Hash` object, that contains structured, pre-fabricated data of our choosing that we can use for our `it` example.

### Usage

##### What is a template?

Templates are effectively `Hash` schemas. By defining a template, you are specifying which named-values can appear in a `Hash` instance of that template. When defining a template, you can also define custom presets, sequences, and other named options. You can leverage these features to simplify how you create complex objects & test data.

##### Defining templates

Templates are defined in `spec/templates/**/*.rb` files. Define a template using the `Olfactory#template` method.

    Olfactory.template :computer do |t|
      ...
    end

Once defined, these templates can be instantiated using `build` and `create`, which are analogous to the same `factory_girl`/`fabrication` methods

    Olfactory.build :computer # Creates objects, but does not implictly save them
    Olfactory.create :computer # Creates objects, and attempts to save all items in the Hash that respond to #save!

Invoking these two methods will return a `Hash` matching the template schema, populated with either custom or preset values.

##### Defining template relationships using `has` & `embeds`

Every template is composed of two kinds of named values: *fields* or other *templates*.

Fields hold actual values: integers, strings, objects, etc. The `has` relation is used define a field. `#has_one` holds one object, and '#has_many' holds a collection of objects (`Array` or `Hash`.)

You can also embed a template within another template. This is useful if you have a template composed of other smaller sub-templates (e.g. a Computer template composed of Processor and Memory templates.) Use the `embeds` relation to nest a template. `#embeds_one` will embed a single instance of a template. `#embeds_many` will embed a collection of template instances (in the form of an `Array` or `Hash`.)

##### #has_one

Defines a field containing a single object.

Definition:
> **has_one** :name *[, :alias => alias_name]*

- `:alias` defines an alias keyword for setting the item value.

When using:
> **name|alias_name** object|&block

Sample:

    # Template definition
    Olfactory.template :computer do |t|
      t.has_one :keyboard
      t.has_one :mouse
      t.has_one :cpu, :alias => :processor
    end
    # Build instance of template
    Olfactory.build :computer do |c|
      c.keyboard "X4 Sidewinder"
      c.mouse { FactoryGirl::build(:mouse) }
      c.processor "Intel Xeon"
    end
    # Result
    {
      :keyboard => "X4 Sidewinder",
      :mouse => <Mouse>,
      :cpu => "Intel Xeon"
    }

##### #has_many

Defines a collection of objects. Each invocation appends the resulting items to the collection. Collection is `nil` by default (if no items are added.)

Definition:
> **has_many** :name *[, :alias => alias_name,
>                   :singular => singular_name,
>                   :named => true|false]*

- `:alias` defines an alias keyword for adding mutiple items to the collection.
- `:singular` defines the keyword for adding singular items to the collection.
- `:named` converts the collection to a `Hash`. When true, all invocations must provide a name (first argument.)

When using as generic collection (`named == false`):
> Singular:
>
> **singular_name** Object
> 
> **singular_name** { &block }
>
> Plural:
> 
> **name|alias_name** quantity:Integer { &block }
> 
> **name|alias_name** objects:Array
> 
> **name|alias_name** object1, object2...

When using as a named collection(`named == true`):
> Singular:
>
> **singular_name** variable_name, Object
> 
> **singular_name** variable_name { &block }
>
> Plural:
> 
> **name|alias_name** Hash

Sample:

    # Template definition
    Olfactory.template :computer do |t|
      # Generic
      t.has_many :cpus
      t.has_many :memory_sticks, :singular => :memory_stick
      
      t.has_many :usb_ports
      
      # Named
      t.has_many :drives, :singular => :drive, :named => true
    end
    # Build instance of template
    Olfactory.build :computer do |c|
      # Generic
      c.cpus "Intel i7", "Onboard graphics"
      c.memory_stick "2GB"
      c.memory_stick "2GB"
      c.usb_ports 2 do
        "2.0"
      end
      c.usb_ports ["2.0", "2.0"]
      c.usb_ports "3.0", "3.0"
      
      # Named
      c.drive :ssd "Samsung"
      c.drives { :hdd => "Seagate", :optical => "Memorex" }
    end
    # Result
    {
      :cpus => ["Intel i7", "Onboard graphics"],
      :memory_sticks => ["2GB", "2GB"],
      :drives => {
        :ssd => "Samsung",
        :hdd => "Seagate",
        :optical => "Memorex"
      },
      :usb_ports => ["2.0", "2.0", "2.0", "2.0", "3.0", "3.0"]
    }
    
##### #embeds_one

Defines a field containing an embedded template.

Definition:
> **embeds_one** :name *[, :alias => alias_name, :template => template_name]*

- `:alias` defines an alias keyword for setting the embedded template value.
- `:template` defines the actual name of the template used, if it does not match the name.

When using:
> **name|alias_name** *[preset_name, { &block }]*

Sample:

    # Template definition
    Olfactory.template :computer do |t|
      t.embeds_one :cpu
      t.embeds_one :gpu, :template => :cpu
    end
    Olfactory.template :cpu do |t|
      t.has_many :cores
      preset :amd do |p|
        p.cores "AMD Core", "AMD Core"
      end
    end
    # Build instance of template
    Olfactory.build :computer do |computer|
      computer.cpu do |cpu|
        cpu.cores "Intel Core", "Intel Core"
      end
      computer.gpu :amd
    end
    # Result
    {
      :cpu => {
                :cpu_core => ["Intel Core", "Intel Core"]
              },
      :gpu => {
                :gpu_core => ["AMD Core", "AMD Core"]
              }
    }
    
##### #embeds_many

Defines a collection of templates. Each invocation appends the resulting templates to the collection. Collection is `nil` by default (if no templates are added.)

Definition:
> **has_many** :name *[, :alias => alias_name,
>                   :template => template_name,
>                   :singular => singular_name,
>                   :named => true|false]*

- `:alias` defines an alias keyword for adding mutiple templates to the collection.
- `:template` defines the actual name of the template used, if it does not match the name.
- `:singular` defines the keyword for adding singular templates to the collection.
- `:named` converts the collection to a `Hash`. When true, all invocations must provide a name (first argument.)

When using as generic collection (`named == false`):
> Singular:
>
> **singular_name**
> 
> **singular_name** preset_name
>
> **singular_name** { &block }
>
> Plural:
> 
> **name|alias_name** quantity:Integer
> 
> **name|alias_name** preset_name, quantity:Integer
> 
> **name|alias_name** quantity:Integer, preset_name
> 
> **name|alias_name** quantity:Integer { &block }

When using as a named collection(`named == true`):
> Singular:
> 
> **singular_name** variable_name
>
> **singular_name** variable_name, preset_name
> 
> **singular_name** variable_name { &block }
>
> Plural:
> 
> (None)

Sample:

    # Template definition
    Olfactory.template :computer do |t|
      # Generic
      t.embeds_many :cpus, :singular => :cpu
      t.embeds_many :drives, :singular => :drive, :named => true
    end
    Olfactory.template :cpu do |t|
      # Generic
      t.has_many :cores, :singular => :core
      t.preset :amd do |p|
        p.cores "AMD Core", "AMD Core"
      end
    end
    Olfactory.template :drive do |t|
      # Generic
      t.has_one :storage_size
      t.has_one :manufacturer
      t.preset :samsung_512gb do |p|
        p.storage_size 512000
        p.manufacturer "Samsung"
      end
    end
    # Build instance of template
    Olfactory.build :computer do |c|
      # Generic
      computer.cpu :amd
      computer.cpu do |cpu|
        cpu.cores "Intel Core", "Intel Core"
      end
      computer.cpus 2 # Creates 2 :cpu templates with defaults
      computer.cpus :amd, 2
      computer.cpus 2, :amd
      computer.cpus 2 do |cpu|
        cpu.cores "Intel Core", "Intel Core"
      end
      
      # Named
      computer.drive :hdd # Creates :drive template with defaults
      computer.drive :ssd, :samsung_512gb
      computer.drive :optical do |drive|
        drive.manufacturer "Memorex"
      end
    end

##### #sequence

Defines a sequence, similar to `factory_girl`'s sequences. Can be combined with `Faker` to provide auto-generated test data. They can be defined at the global level, or nested within a template.

###### When defining at the global level

Definition:
> **Olfactory.sequence** :name*[, :seed => Integer]* { |iterator[,options]| &block }

- `seed` defines the starting value, which increments by 1 after each invocation. Default 0.
- `options` in the form of hash args can be passed to the block.
- `iterator` is the current seed, which starts at 0 by default.
- `block` generates and returns the value.

Usage:
> **Olfactory.generate** :name
> 
> **Olfactory.generate** :name, :option1 => Object, :option2 => Object...
> 
> **Olfactory.generate** :name, :seed => Integer
> 
> **Olfactory.generate** :name, :seed => Integer, :option1 => Object, :option2 => Object...
> 
> **Olfactory.generate** :name { |iterator, options| &block }

 - `seed` can be provided to override whatever the current seed is. When you provide an overriding seed, the sequence will *not* increment its internal seed. (Will act like it was never called.)
 - `options` in the form of hash args can be passed to the block.
 - `block` can be provided to override the block used for the call. When you provide an overriding block, the sequence will still increment its internal seed.

Sample:

    Olfactory.sequence :ip_address, :seed => 1 do |n, options|
      options[:ipv6] ? "fe80::2a18:78ff:feba:#{n}" : "192.168.1.#{n % 255}"
    end
    Olfactory.generate(:ip_address) # => "192.168.1.1"
    Olfactory.generate(:ip_address, :seed => 255) # => "192.168.1.255"
    Olfactory.generate(:ip_address) # => "192.168.1.2"
    Olfactory.generate(:ip_address, :ipv6 => true) # => "fe80::2a18:78ff:feba:3"
    Olfactory.generate(:ip_address) do |n|
      "172.168.1.#{n % 255}"
    end # => "172.168.1.4"
    
###### When defining at the template level

`Olfactory` sequences don't provide much benefit over other gems at the global level, but they really shine when used within templates. Sequences work exactly the same within templates, except they can be bound by `scope`, allowing the author a great deal of control over when sequences reset.

`scope` can either be `:instance`, which resets the seed for each instance of the template, or `:template`, which shares the seed across all instances of the template.

Sample:

    # Template definition
    Olfactory.template :computer do |t|
      t.has_one :serial_number
      t.sequence :serial_number, :scope => :template do |n|
        (10000 + n)
      end
      t.has_many :registers, :singular => :register
      t.sequence :register, :scope => :instance do |n|
        "Register #{n+1}"
      end
    end
    
    Olfactory.build :computer do |c|
      c.serial_number { c.generate(:serial_number) }
      c.registers 2 { c.generate(:register) }
    end
    # => { :serial_number => 10000, :registers => ["Register 1", "Register 2"] }
    
    Olfactory.build :computer do |c|
      c.serial_number { c.generate(:serial_number) }
      c.registers 2 { c.generate(:register) }
    end
    # => { :serial_number => 10001, :registers => ["Register 1", "Register 2"] }

##### #dictionary

Defines a dictionary, which is just a simple data store (Hash.) They can be defined at the global level, or nested within a template.

###### When defining at the global level

Definition:
> **Olfactory.dictionary** :name

Usage:
> **Olfactory.dictionaries**[name] # Returns Hash to read/write from

Sample:

    Olfactory.dictionary :manfacturer_codes
    Olfactory.dictionaries[:manfacturer_codes]["DELL"] = "Dell Computing"

###### When defining at the template level

A hash data-store isn't that special at the global level, but is much more useful within templates. Definition is the same, but the usage only differs by name. Like sequences, dictionaries can define `scope` to separate or share data across templates. Combining them with sequences, we can synchronize data in some really cool ways.

`scope` can either be `:instance`, which resets the hash for each instance of the template, or `:template`, which shares the hash across all instances of the template.

Sample:

    Olfactory.template :computer do |t|
      t.has_one :hdd_manfacturer_code
      t.has_one :gpu_manfacturer_code
      t.has_one :cpu_manfacturer_code
      t.dictionary :manfacturer_codes, :scope => :template
      t.sequence :manfacturer_code, :scope => :template do |n|
        (10000 + n)
      end
    end
    
    Olfactory.build :computer do |c|
      c.hdd_manfacturer_code { c.manfacturer_codes["SAMSUNG"] ||= c.generate(:manfacturer_code) }
      c.cpu_manfacturer_code { c.manfacturer_codes["AMD"] ||= c.generate(:manfacturer_code) }
      c.gpu_manfacturer_code { c.manfacturer_codes["AMD"] ||= c.generate(:manfacturer_code) }
    end
    # => { :hdd_manfacturer_code => 10001,
    #      :cpu_manfacturer_code => 10002,
    #      :cpu_manfacturer_code => 10002 }
    
    Olfactory.build :computer do |c|
      c.hdd_manfacturer_code { c.manfacturer_codes["SEAGATE"] ||= c.generate(:manfacturer_code) }
      c.cpu_manfacturer_code { c.manfacturer_codes["AMD"] ||= c.generate(:manfacturer_code) }
      c.gpu_manfacturer_code { c.manfacturer_codes["INTEL"] ||= c.generate(:manfacturer_code) }
    end
    # => { :hdd_manfacturer_code => 10003,
    #      :cpu_manfacturer_code => 10002,
    #      :cpu_manfacturer_code => 10004 }
    
##### #preset

Defines a preset of values.

Definition:
> **preset** :name { |instance| &block }

When using:
> Olfactory.build template_name, :preset => preset_name, :quantity => quantity:Integer

See above sections for usage within templates.

Sample:

    # Template definition
    Olfactory.template :computer do |t|
      t.embeds_many :cpus
      t.preset :dual_core do |p|
        p.cpus 2 do |cpu|
          cpu.core "Intel Core"
        end
      end
    end
    Olfactory.template :cpu do |t|
      t.has_one :cpu_core
    end
    # Build instance of template
    Olfactory.build :computer, :preset => :dual_core
    # Result
    {
      :cpus => [{
                :cpu_core => "Intel Core"
              },
              {
                :cpu_core => "Intel Core"
              }]
    }
    
##### #macro

Similar to a preset, `macro` defines a 'function' that can be used within a template, which can accept parameters, and set variables or invoke code. The result of this macro will *not* be stored on the resulting template. 

Definition:
> **macro** :name { |instance, *args..| &block }

When using:
> **name** arg1, arg2...

Sample:

    # Template defintion
    Olfactory.template :computer do |t|
      t.has_one :memory_size
      t.macro :memory_sticks do |d, num|
        d.memory_size "{num*4}GB"
      end
    end
    # Build instance of template
    Olfactory.build :computer do |c|
      c.memory_sticks 2
    end
    # Result 
    {
      :memory_size => "8GB"
    }

##### #transient
 
Similar to `factory_girl`'s transients, `transient` defines a temporary variable. You can store values in here to compose conditional logic or more sophisticated templates. When a template contains an embedded template, it will pass down all of its transients to the embedded template. Invoking `transients` on an instance of a template will return a `Hash` of its transient variables.

Usage:
> **transient** name, Object # Sets value
> 
> **transient** name { Object } # Sets value (lazily)
> 
> **transients**[name] # Gets value

Sample:

    # Template defintion
    Olfactory.template :computer do |t|
      t.has_one :memory_size
      t.embeds_one :cpu
      t.macro :memory_sticks do |d, num|
        d.memory_size "{num*(d.transients[:memory_stick_size] || 4)}GB"
      end
      t.macro :memory_stick_size do |m, size|
        t.transient :memory_stick_size, size
      end
    end
    Olfactory.template :cpu do |t|
      t.has_one :available_memory
    end
    # Build instance of template
    Olfactory.build :computer do |c|
      c.memory_stick_size 2
      c.memory_sticks 2
      c.cpu do |cpu|
        cpu.memory_module_size "#{cpu.transients[:memory_stick_size]}GB"
      end
    end
    # Result
    {
      :memory_size => "4GB",
      :cpu => {
                :memory_module_size => "2GB"
              }
    }

##### Defaults: #before & #after

Defines default values, which are used to fill in any empty `has`, `embeds` or `transient` fields, before and after respectively. They will *not* overwrite any non-nil value.

Definition:
> **before**(*:context, :run => Symbol*) { |instance| &block }
> 
> **after** { |instance| &block }

- `:context` defines when this before should run. Specifying `:embedded` means it runs just before embedded objects are added to the instance. Default (by providing no value) is to run immediately as instance is created.
- `:run` defines how many times this before can be invoked for an instance. Specifying `:once` means it can only be invoked once (singleton-style.) Default is to always execute. Can only be specified if `:context` is also specified.

The latter two options can be useful if you are embedding a template that reads the parent's fields or transients.

Sample:

    # Template defintion
    Olfactory.template :computer do |t|
      t.has_one :cpu
      t.has_one :memory_size
      t.before do |d|
        d.cpu "Intel Xeon"
        d.memory_size "4GB"
      end
    end
    # Build instance of template
    Olfactory.build :computer do |c|
      c.cpu "AMD Athlon"
    end
    # Result 
    {
      :cpu => "AMD Athlon",
      :memory_size => "4GB"
    }
    
    # Template defintion
    Olfactory.template :phone do |t|
      t.has_one :cpu
      t.has_one :memory_size
      t.after do |d|
        d.cpu "ARM"
        d.memory_size "2GB"
      end
    end
    # Build instance of template
    Olfactory.build :phone do |c|
      c.memory_size "1GB"
    end
    # Result 
    {
      :memory_size => "1GB",
      :cpu => "ARM"
    }

Another `before` sample using `:context` and `:run` options:

    # Template defintions
    Olfactory.template :widget do |t|
      t.embeds_many :doodads, :singular => :doodad
      t.has_one :thingamabob
      t.macro :quality do |m, type|
        m.transient :attribute, type.to_s
      end
      t.before(:embedded) do |d|
        d.quality :dull
        d.thingamabob "thingamabob" if d[:doodads] && d[:doodads].count > 0
      end
    end
    Olfactory.template :doodad do |t|
      t.has_one :gizmo
      t.after do |d|
        d.gizmo "#{d.transients[:attribute]} doodad"
      end
    end
    # Build instance of template
    Olfactory.build :widget do |w|
      w.doodad
      w.quality :shiny
      w.doodad
    end
    # Result
    {
      :doodads => [{ :gizmo => "dull doodad" },
                   { :gizmo => "shiny doodad" }]
      # NOTE: A 'thingamabob' wasn't added. This is because the #before only ran once.
    }

##### #instantiate

Defines an 'instantiator': a function you can call to build custom objects from an instance of a template. The block can accept arguments or use the template instance as input, and should return an object or collection. Invoke the block using the `#build` or `#create` method to get the return value from the instantiator. When `#create` is used, any object that responds to `#save!` will be saved.

Definition:
> **instantiate** :name { |instance, *args..| &block }

When using:
> **build**(name*[, arg1, arg2...]*)
> 
> **create**(name*[, arg1, arg2...]*)

Sample:

    # Template defintion
    Olfactory.template :widget do |t|
      t.has_one :doodad
      t.instantiate :doodad do |i, j|
        String.new("#{i[:doodad]}-instance-#{j}")
      end
    end
    # Build instance of template
    instance = Olfactory.build :widget do |w| w.doodad "doodad" end
    instance.build(:doodad, 1)
    # Result
    "doodad-instance-1"

### Changelog

#### Version 0.2.1

 - Added: `context` and `run` options to `before` blocks.
 - Added: `dimension` option to sequences, to allow scoping.
 - Fixed: Default values not being overridden in special cases.
 - Fixed: Defaults adding to item and subtemplate collections.

#### Version 0.2.0

 - Added: Sequences (like factory_girl's)
 - Added: Dictionaries (generic hash storage)
 - Changed: `#build_template` and `#create_template` have been renamed to `#build` and `#create` respectively.

#### Version 0.1.0

 - Initial version of Olfactory (templates, transients, macros, presets, has/embeds relations)
