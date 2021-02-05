import { escapeExpression, formatUsername } from "discourse/lib/utilities";
import I18n from "I18n";
import RawHtml from "discourse/widgets/raw-html";
import { avatarImg } from "discourse/widgets/post";
import { createWidget } from "discourse/widgets/widget";
import { dateNode } from "discourse/helpers/node";
import { emojiUnescape } from "discourse/lib/text";
import { h } from "virtual-dom";
import highlightSearch from "discourse/lib/highlight-search";
import { iconNode } from "discourse-common/lib/icon-library";
import renderTag from "discourse/lib/render-tag";
import DiscourseURL from "discourse/lib/url";
import getURL from "discourse-common/lib/get-url";
import { wantsNewWindow } from "discourse/lib/intercept-click";
import { htmlSafe } from "@ember/template";
import { registerUnbound } from "discourse-common/lib/helpers";
import renderTags from "discourse/lib/render-tags";
import TopicStatusIcons from "discourse/helpers/topic-status-icons";

class Highlighted extends RawHtml {
  constructor(html, term) {
    super({ html: `<span>${html}</span>` });
    this.term = term;
  }

  decorate($html) {
    highlightSearch($html[0], this.term);
  }
}



export default {
  name: "wizard-register-widgets",
  after: "custom-routes",
  initialize(app) {
    if (window.location.pathname.indexOf("/w/") < 0) return;

    createWidget("link", {
      tagName: "a",
    
      href(attrs) {
        const route = attrs.route;
        if (route) {
          const router = this.register.lookup("router:main");
          if (router && router._routerMicrolib) {
            const params = [route];
            if (attrs.model) {
              params.push(attrs.model);
            }
            return getURL(
              router._routerMicrolib.generate.apply(router._routerMicrolib, params)
            );
          }
        } else {
          return getURL(attrs.href);
        }
      },
    
      buildClasses(attrs) {
        const result = [];
        result.push("widget-link");
        if (attrs.className) {
          result.push(attrs.className);
        }
        return result;
      },
    
      buildAttributes(attrs) {
        const ret = {
          href: this.href(attrs),
          title: attrs.title
            ? I18n.t(attrs.title, attrs.titleOptions)
            : this.label(attrs),
        };
        if (attrs.attributes) {
          Object.keys(attrs.attributes).forEach(
            (k) => (ret[k] = attrs.attributes[k])
          );
        }
        return ret;
      },
    
      label(attrs) {
        if (attrs.labelCount && attrs.count) {
          return I18n.t(attrs.labelCount, { count: attrs.count });
        }
        return attrs.rawLabel || (attrs.label ? I18n.t(attrs.label) : "");
      },
    
      html(attrs) {
        if (attrs.contents) {
          return attrs.contents();
        }
    
        const result = [];
        if (attrs.icon) {
          if (attrs.alt) {
            let icon = iconNode(attrs.icon);
            icon.properties.attributes["alt"] = I18n.t(attrs.alt);
            icon.properties.attributes["aria-hidden"] = false;
            result.push(icon);
          } else {
            result.push(iconNode(attrs.icon));
          }
          result.push(" ");
        }
    
        if (!attrs.hideLabel) {
          let label = this.label(attrs);
    
          if (attrs.omitSpan) {
            result.push(label);
          } else {
            result.push(h("span.d-label", label));
          }
        }
    
        const currentUser = this.currentUser;
        if (currentUser && attrs.badgeCount) {
          const val = parseInt(currentUser.get(attrs.badgeCount), 10);
          if (val > 0) {
            const title = attrs.badgeTitle ? I18n.t(attrs.badgeTitle) : "";
            result.push(" ");
            result.push(
              h(
                "span.badge-notification",
                {
                  className: attrs.badgeClass,
                  attributes: { title },
                },
                val
              )
            );
          }
        }
        return result;
      },
    
      click(e) {
        if (this.attrs.attributes && this.attrs.attributes.target === "_blank") {
          return;
        }
    
        if (wantsNewWindow(e)) {
          return;
        }
    
        e.preventDefault();
    
        if (this.attrs.action) {
          e.preventDefault();
          return this.sendWidgetAction(this.attrs.action, this.attrs.actionParam);
        } else {
          this.sendWidgetEvent("linkClicked", this.attrs);
        }
    
        return DiscourseURL.routeToTag($(e.target).closest("a")[0]);
      },
    });
   createWidget("topic-status", {
      tagName: "div.topic-statuses",
    
      html(attrs) {
        const topic = attrs.topic;
        const canAct = this.currentUser && !attrs.disableActions;
    
        const result = [];
        TopicStatusIcons.render(topic, function (name, key) {
          const iconArgs = key === "unpinned" ? { class: "unpinned" } : null;
          const icon = iconNode(name, iconArgs);
    
          const attributes = {
            title: escapeExpression(I18n.t(`topic_statuses.${key}.help`)),
          };
          result.push(h(`${canAct ? "a" : "span"}.topic-status`, attributes, icon));
        });
    
        return result;
      },
    });
    
    createSearchResult({
      type: "topic",
      linkField: "url",
      builder(result, term) {
        const topic = result;
    
        const firstLine = [
          this.attach("topic-status", { topic, disableActions: true }),
          h(
            "span.topic-title",
            { attributes: { "data-topic-id": topic.id } },
            this.siteSettings.use_pg_headlines_for_excerpt &&
              result.topic_title_headline
              ? new RawHtml({
                  html: `<span>${emojiUnescape(
                    result.topic_title_headline
                  )}</span>`,
                })
              : new Highlighted(topic.fancy_title, term)
          ),
        ];
    
        const secondLine = [
          // this.attach("category-link", {
          //   category: topic.category,
          //   link: false,
          // }),
        ];
        // if (this.siteSettings.tagging_enabled) {
        //   secondLine.push(
        //     this.attach("discourse-tags", { topic, tagName: "span" })
        //   );
        // }
    
        const link = h("span.topic", [
          h("div.first-line", firstLine),
          h("div.second-line", secondLine),
        ]);
    
        return postResult.call(this, result, link, term);
      },
    });
    
  }
}

function createSearchResult({ type, linkField, builder }) {
  return createWidget(`search-result-${type}`, {
    tagName: "ul.list",

    html(attrs) {
      return attrs.results.map((r) => {
        let searchResultId;

        if (type === "topic") {
          searchResultId = r.topic_id;
        } else {
          searchResultId = r.id;
        }

        return h(
          "li.item",
          this.attach("link", {
            href: r[linkField],
            contents: () => builder.call(this, r, attrs.term),
            className: "search-link",
            searchResultId,
            searchResultType: type,
            searchContextEnabled: attrs.searchContextEnabled,
            searchLogId: attrs.searchLogId,
          })
        );
      });
    },
  });
}

function postResult(result, link, term) {
  const html = [link];

  if (!this.site.mobileView) {
    html.push(
      h("span.blurb", [
        dateNode(result.created_at),
        h("span", " - "),
        this.siteSettings.use_pg_headlines_for_excerpt
          ? new RawHtml({ html: `<span>${result.blurb}</span>` })
          : new Highlighted(result.blurb, term),
      ])
    );
  }

  return html;
}