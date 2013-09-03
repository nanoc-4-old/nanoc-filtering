# encoding: utf-8

require 'helper'

require 'haml'

class Nanoc::Filtering::HelperTest < Minitest::Test

  include Nanoc::Filtering::Helper

  def test_filter_with_assigns
    # Build content to be evaluated
    content = "<p>Foo...</p>\n" +
              "<% filter :erb do %>\n" +
              " <p><%%= @item[:title] %></p>\n" +
              "<% end %>\n"

    # Mock item and rep
    @item = Nanoc::Item.new('content', { :title => 'Bar...' }, '/blah/')
    @item_rep = OpenStruct.new(
      :name => 'default',
      :assigns => { :item => @item })
    @item_rep.assigns[:item_rep] = @item_rep

    # Evaluate content
    result = ::ERB.new(content).result(binding)

    # Check
    assert_match('<p>Foo...</p>', result)
    assert_match('<p>Bar...</p>', result)
  end

  def test_filter_with_unknown_filter_name
    # Build content to be evaluated
    content = "<p>Foo...</p>\n" +
              "<% filter :askjdflkawgjlkwaheflnvz do %>\n" +
              " <p>Blah blah blah.</p>\n" +
              "<% end %>\n"

    # Evaluate content
    assert_raises(Nanoc::Errors::UnknownFilter) do
      ::ERB.new(content).result(binding)
    end
  end

  def test_filter_with_arguments
    # Build content to be evaluated
    content = "<% filter :erb, :language => 'ruby' do %>\n" +
              "   <%%= 'foo' %><%%= 'bar' %>\n" +
              "<% end %>\n"

    # Mock item and rep
    @item_rep = OpenStruct.new(:assigns => {})

    # Evaluate content
    result = ::ERB.new(content).result(binding)
    assert_match(/foobar/, result)
  end

  def test_with_haml
    # Build content to be evaluated
    content = "%p Foo.\n" +
              "- filter(:erb) do\n" +
              "  <%= 'abc' + 'xyz' %>\n" +
              "%p Bar.\n"

    # Mock item and rep
    @item_rep = OpenStruct.new(:assigns => {})

    # Evaluate content
    result = ::Haml::Engine.new(content).render(binding)
    assert_match(%r{^<p>Foo.</p>\s*abcxyz\s*<p>Bar.</p>$}, result)
  end

  def test_notifications
    notifications = Set.new
    Nanoc::NotificationCenter.on(:filtering_started) { notifications << :filtering_started }
    Nanoc::NotificationCenter.on(:filtering_ended)   { notifications << :filtering_ended   }

    # Build content to be evaluated
    content = "<% filter :erb do %>\n" +
              "   ... stuff ...\n" +
              "<% end %>\n"

    # Mock item and rep
    @item_rep = OpenStruct.new(:assigns => {})

    ::ERB.new(content).result(binding)

    assert notifications.include?(:filtering_started)
    assert notifications.include?(:filtering_ended)
  end

end
