import { click, visit } from "@ember/test-helpers";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import { test } from "qunit";

acceptance("Category Chooser Initializer for regular users", function (needs) {
  needs.user({ admin: false, moderator: false });
  needs.settings({
    allow_uncategorized_topics: false,
  });
  needs.site({
    can_tag_topics: true,
    categories: [
      {
        id: 1,
        name: "General",
        slug: "general",
        permission: 1,
        topic_template: null,
      },
      {
        id: 2,
        name: "Category with custom field",
        slug: "category-custom-field",
        permission: 1,
        topic_template: "",
        custom_fields: {
          create_topic_wizard: "21",
        },
      },
      {
        id: 3,
        name: "Category 1",
        slug: "category-1",
        permission: 1,
        topic_template: "",
      },
      {
        id: 4,
        name: "Category 2",
        slug: "category-2",
        permission: 1,
        topic_template: "",
      },
    ],
  });

  test("does not display category with create_topic_wizard for regular users", async function (assert) {
    const categoryChooser = selectKit(".category-chooser");
    await visit("/");
    await click("#create-topic");
    await categoryChooser.expand();
    let categories = Array.from(
      document.querySelectorAll(".category-chooser .category-row")
    ).filter((category) => category.getAttribute("data-name")); // Filter elements with a data-name attribute
    assert.equal(
      categories.length,
      3,
      "Correct number of categories are displayed"
    );
    const categoryNames = ["General", "Category 1", "Category 2"];

    categoryNames.forEach((categoryName) => {
      assert.ok(
        categories.some(
          (category) => category.getAttribute("data-name") === categoryName
        ),
        `Category '${categoryName}' is displayed`
      );
    });

    const categoryNameWithCustomField = "Category with custom field";
    assert.notOk(
      categories.some(
        (category) =>
          category.getAttribute("data-name") === categoryNameWithCustomField
      ),
      `Category '${categoryNameWithCustomField}' is not displayed`
    );
  });
});

acceptance("Category Chooser Initializer for Admins", function (needs) {
  needs.user({ admin: true });
  needs.settings({
    allow_uncategorized_topics: false,
  });
  needs.site({
    can_tag_topics: true,
    categories: [
      {
        id: 1,
        name: "General",
        slug: "general",
        permission: 1,
        topic_template: null,
      },
      {
        id: 2,
        name: "Category with custom field",
        slug: "category-custom-field",
        permission: 1,
        topic_template: "",
        custom_fields: {
          create_topic_wizard: "21",
        },
      },
      {
        id: 3,
        name: "Category 1",
        slug: "category-1",
        permission: 1,
        topic_template: "",
      },
      {
        id: 4,
        name: "Category 2",
        slug: "category-2",
        permission: 1,
        topic_template: "",
      },
    ],
  });

  test("displays all categories", async function (assert) {
    const categoryChooser = selectKit(".category-chooser");
    await visit("/");
    await click("#create-topic");
    await categoryChooser.expand();
    let categories = Array.from(
      document.querySelectorAll(".category-chooser .category-row")
    ).filter((category) => category.getAttribute("data-name")); // Filter elements with a data-name attribute
    assert.equal(
      categories.length,
      4,
      "Correct number of categories are displayed"
    );
    const categoryNames = [
      "General",
      "Category 1",
      "Category 2",
      "Category with custom field",
    ];

    categoryNames.forEach((categoryName) => {
      assert.ok(
        categories.some(
          (category) => category.getAttribute("data-name") === categoryName
        ),
        `Category '${categoryName}' is displayed`
      );
    });
  });
});
acceptance("Category Chooser Initializer for Staff", function (needs) {
  needs.user({ staff: true });
  needs.settings({
    allow_uncategorized_topics: false,
  });
  needs.site({
    can_tag_topics: true,
    categories: [
      {
        id: 1,
        name: "General",
        slug: "general",
        permission: 1,
        topic_template: null,
      },
      {
        id: 2,
        name: "Category with custom field",
        slug: "category-custom-field",
        permission: 1,
        topic_template: "",
        custom_fields: {
          create_topic_wizard: "21",
        },
      },
      {
        id: 3,
        name: "Category 1",
        slug: "category-1",
        permission: 1,
        topic_template: "",
      },
      {
        id: 4,
        name: "Category 2",
        slug: "category-2",
        permission: 1,
        topic_template: "",
      },
    ],
  });

  test("displays all categories", async function (assert) {
    const categoryChooser = selectKit(".category-chooser");
    await visit("/");
    await click("#create-topic");
    await categoryChooser.expand();
    let categories = Array.from(
      document.querySelectorAll(".category-chooser .category-row")
    ).filter((category) => category.getAttribute("data-name")); // Filter elements with a data-name attribute
    assert.equal(
      categories.length,
      4,
      "Correct number of categories are displayed"
    );
    const categoryNames = [
      "General",
      "Category 1",
      "Category 2",
      "Category with custom field",
    ];

    categoryNames.forEach((categoryName) => {
      assert.ok(
        categories.some(
          (category) => category.getAttribute("data-name") === categoryName
        ),
        `Category '${categoryName}' is displayed`
      );
    });
  });
});
