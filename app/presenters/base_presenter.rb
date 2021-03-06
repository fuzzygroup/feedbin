class BasePresenter

  def initialize(object, locals, template)
    @object = object
    @locals = locals
    @template = template
  end

  def favicon(feed)
    @favicon ||= begin
      if feed.newsletter?
        content = @template.content_tag :span, '', class: "favicon-wrap collection-favicon favicon-newsletter-wrap" do
          @template.svg_tag('favicon-newsletter', size: "16x16")
        end
      else
        markup = <<-eos
          <span class="favicon favicon-default"></span>
        eos
        if feed.favicon && feed.favicon.cdn_url
          markup = <<-eos
            <span class="favicon" style="background-image: url(#{feed.favicon.cdn_url});"></span>
          eos
        end
        content = <<-eos
          <span class="favicon-wrap">
            #{markup}
          </span>
        eos
      end
      content.html_safe
    end
  end

  private

  def self.presents(name)
    define_method(name) do
      @object
    end
  end

end