# frozen_string_literal: true

module FormNumber
  PATTERNS = {
    allianz: /\n\w{4}-.{2} .{4} \(.{2}-.{2,4}\)/,
    allied: %r{\n\w{2} .{5} .{2} \(.{2}/.{2}\)},
    axis: /\n\w{3} .{4} \(?.{2}[\s-]?.{2}\)?/,
    berkley: /\n\w{2} .{5,6} \(.{2}-.{2}\)/,
    berkshire: %r{\s\w{2}-.{4}-.{3}-.{3}-.{2}/.{4}},
    everest: /\n.{3}-.{7}-.{1,6}/,
    great_american: %r{\nD.{6}\s?\(.{2}/.{2}\)},
    liberty: /\n(.{4} .{6}) .{4} \(.*?\)/,
    liberty_alt: /\n(.{6})-.{4}-.{4}(?:\(Ex\))?/,
    zurich: %r{\nU-.{2}-?.?-(.*?)CW \(.{2}/.{2}\)},
    arch: /\n.{2} .{7} .{2} .{2} .{2}/,
    xl: /\n.[BRX]+ .{2} .{2,3} .{2}\s?.{2}/,
    national_union: %r{\n\d{6} \(.{1,2}/.{1,2}\)}
  }.freeze
end
