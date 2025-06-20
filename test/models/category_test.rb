require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  def test_should_be_valid_with_valid_name
    category = Category.new(name: "Test Category")
    assert category.valid?
  end

  def test_should_require_name
    category = Category.new(name: nil)
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  def test_should_require_unique_name
    Category.create!(name: "Unique Category")
    duplicate_category = Category.new(name: "Unique Category")
    assert_not duplicate_category.valid?
    assert_includes duplicate_category.errors[:name], "has already been taken"
  end

  def test_should_have_many_zines
    category = Category.create!(name: "Test Category")
    zine1 = Zine.create!(title: "Zine 1", created_by: "Creator 1", category: category)
    zine2 = Zine.create!(title: "Zine 2", created_by: "Creator 2", category: category)

    assert_includes category.zines, zine1
    assert_includes category.zines, zine2
    assert_equal 2, category.zines.count
  end

  def test_should_not_allow_deletion_with_associated_zines
    category = Category.create!(name: "Test Category")
    Zine.create!(title: "Test Zine", created_by: "Creator", category: category)

    assert_raises(ActiveRecord::RecordNotDestroyed) do
      category.destroy!
    end
  end
end
