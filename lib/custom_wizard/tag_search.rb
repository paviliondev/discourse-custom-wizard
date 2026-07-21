# frozen_string_literal: true

class CustomWizard::TagSearch
  def initialize(guardian, params)
    @guardian = guardian
    @params = params
  end

  def results
    tags = DiscourseTagging.filter_allowed_tags(@guardian, **filter_options)
    ::TagsController.tag_counts_json(Tag.with_localizations(tags), @guardian)
  end

  private

  def filter_options
    opts = { limit: capped_limit }
    opts[:selected_tag_ids] = selected_tag_ids if selected_tag_ids.present?
    opts[:only_tag_names] = allowed_tag_names if restricted_to_tags?

    if term.present?
      opts[:term] = term
      opts[:order_search_results] = true
    else
      opts[:order_popularity] = true
    end

    opts
  end

  def restricted_to_tags?
    tag_group_names.present? || content_tag_names.present?
  end

  def allowed_tag_names
    (tag_group_tag_names + content_tag_names).uniq
  end

  def tag_group_names
    @tag_group_names ||= @params[:tag_groups].to_s.split(",").map(&:strip).reject(&:blank?)
  end

  def tag_group_tag_names
    return [] if tag_group_names.blank?

    TagGroup
      .includes(:tags)
      .where(name: tag_group_names)
      .flat_map { |tag_group| tag_group.tags.pluck(:name) }
  end

  def content_tag_names
    @content_tag_names ||= Array(@params[:content]).map { |name| name.to_s.strip }.reject(&:blank?)
  end

  def selected_tag_ids
    @selected_tag_ids ||=
      if @params[:selected_tag_ids].present?
        Array(@params[:selected_tag_ids]).map(&:to_i)
      elsif @params[:selected_tags].present?
        Tag.where_name(Array(@params[:selected_tags])).pluck(:id)
      else
        []
      end
  end

  def term
    @term ||= @params[:q].present? ? DiscourseTagging.clean_tag(@params[:q]) : nil
  end

  def capped_limit
    max = SiteSetting.max_tag_search_results
    [@params[:limit].presence&.to_i || max, max].min
  end
end
