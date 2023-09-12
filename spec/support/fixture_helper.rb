# frozen_string_literal: true

module FixtureHelper
  def file_fixture(filename)
    filepath = File.join(File.dirname(__FILE__), "..", "fixtures", filename)
    File.read(filepath)
  end
end
