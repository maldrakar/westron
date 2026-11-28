#!/usr/bin/env bash
# Which catalog entries a pull request's accessibility audit covers (.github/workflows/ci.yml, `audit-scope`).
#
#   git diff --name-only <base> <head> | tools/apple/audit-scope.sh
#
# Reads changed paths, one per line, and prints one line: the ids of the catalog entries to audit, comma-separated,
# in the order of the registry (`Catalog.entries`), or an empty line when there is nothing to audit. Why each path
# counts, or does not, goes to stderr. The rules:
#   - a path of one component: `platforms/apple/Sources/WestronUI/<Name>/`, its generated `<Name>+Contract.swift` (in
#     WestronUI, and its enums in WestronContract, decisions/0017) and `<Name>+Matrix.swift`, `platforms/apple/Sources/WestronCatalog/Components/<Name>Pages.swift`, its contract
#     `spec/components/<id>/` (`text-field` is `TextField`) → the entries `<Name>Pages.swift` declares, and the
#     entries that draw what changed (see "Use" below). A component of WestronUI without that page fails the script:
#     every component has its catalog entry (Catalog.swift). A contract without one is not implemented on Apple yet,
#     and gives nothing;
#   - a path of one pattern (decisions/0018): its document `spec/patterns/<id>.md` or its catalog source
#     `platforms/apple/Sources/WestronCatalog/Patterns/<Name>/` (`choice-list-sheet` is `ChoiceListSheet`), the
#     pattern's example and the page that shows it → the entries that directory declares, the pattern's own. A pattern
#     whose directory declares no entry has no Apple example in the catalog yet, and gives nothing. A pattern's entry
#     draws components, so its directory is read with the pages below (see "Use"): a component's change selects it too;
#   - a page of WestronCatalog's Foundations, or its root, that declares entries and shares nothing with other files
#     (every other type it declares is used by no other file of WestronCatalog, and it extends no type but
#     CatalogEntry) → those entries;
#   - anything else → nothing. Shared paths (tokens, the shared files of WestronUI, the catalog's host and its shared
#     pages, the audit test, tools/apple/, Package.swift, the workflows) touch every entry: the nightly full audit
#     (.github/workflows/accessibility-audit.yml) covers them, and it can be run by hand on a branch.
# The entry ids come from the sources: `static let <name> = CatalogEntry(id: "<id>", …)` in the pages, and the
# registry, `Catalog.entries` and the arrays it is built from in Catalog.swift, from its `static let entries` to its
# first function: each `.<name>,` line of an array literal and each `append(.<name>)` (an entry some OS lacks, appended
# under `#if`), in the order they stand. An entry its page declares but the registry leaves out is not audited by
# anyone, so it is left out here too. A registry the script reads no entry from fails it, so that a change of the
# registry's shape fails CI's job instead of auditing nothing (tools/apple/audit-scope-test.sh, tools/check.sh step
# audit-scope).
#
# Use. Since phase 4 components draw each other (Disclosure's page holds ListRows, ListRow draws Rule and Checkbox,
# TextField draws Icon), so a change to one can break another's page. The script follows use, derived from the
# sources on every run, not from a list: there is no map to keep. It reads every Swift file of WestronUI and
# WestronContract (whose enums tell a component's style modifier from the system's), the catalog's pages (Components/,
# Patterns/, Foundations/) and its root files that declare entries, without comments and string literals,
# and splits them into units: each top-level declaration; each extension of a type they declare, under that type's
# name; and each member of an extension of a type they do not declare (View, EnvironmentValues, Toggle, CatalogEntry),
# so that every entry, `static let <name> = CatalogEntry(…)`, is a unit of its own. A unit uses another when its code
# names it: a type by its name, unqualified (`ListRow`, not `Westron.Icon`); a top-level `var` or `let` by its name; an
# extension's property as `.<name>` (`\.forcedChipStates`); a function by a call, `.<name>(…)` or `<name>(…)`, or
# with a trailing closure (`.surface(variant)`, `.onChipHover { … }`); an initializer added to a system type by a call
# of that type with its labels, in order (`Toggle(isOn: …, accessibilityLabel: …)`); and a style modifier, a function
# named `…Style` whose first parameter is a component's enum, only by a call with one of that enum's cases written
# out (`.toggleStyle(.check)`, `.buttonStyle(.primary)`), since the system and other components overload it:
# `.buttonStyle(.plain)` is the system's, `.toggleStyle(.chip)` is Chip's, not Checkbox's. A private declaration is
# used only from its own file. Then:
#   - a change to a component's implementation (its WestronUI directory, its generated `<Name>+Contract.swift`, its
#     contract) also selects every entry whose unit reaches a unit of that implementation through uses, at any depth:
#     Checkbox's change selects `disclosure` (DisclosurePage → DisclosureBlockHeader →
#     `Toggle(isOn:accessibilityLabel:)`), Disclosure's selects `list-row` (ListRowPage → listRowChevronToggles →
#     `.onDisclosureToggle`), Rule's selects `color-in-use` (ColorInUsePage → TasksSample → Rule) but not `list-row`,
#     whose way to Rule goes through ListRow, a base component (ListRowPage → ListRowDragSamples → `.insertionMark` →
#     ListRowInsertionMark → Rule);
#   - a change to a component's page also selects every entry that reaches a unit of the page, unless the component is
#     base: `FlowLayout` in ButtonPages.swift is used by the entries checkbox, chip, color-categories, color-in-use and
#     controls, which a change to that page
#     selected until Button was declared base (tools/apple/audit-scope-test.sh holds the rule in a copy with Button's
#     cut lifted);
#   - the cut, declared: a base component (`base_components` below, each with its reason) is drawn on so many entries
#     that auditing them all on its pull requests would cost as much as the nightly full audit. A change to it selects
#     its own entries only and says so; the others wait for the nightly run, as a shared file's do. The search does not
#     go on through a base component's units: a change to something it draws does not select every entry that draws
#     the base component (nor the base component's own entries), and every count below is taken with that stop;
#   - the limit, a tripwire, not a switch: a change that would select more than 5 entries (fan_out_limit, one leg of
#     the audit in ci.yml) beyond its component's own, for a component not declared base, fails the script, naming the
#     component, its count and the choices: declare it base (its changes then audit its own entries only), move a
#     page's shared code out of the page, or raise the limit and accept larger audits. A declared base component whose
#     change would select no more than the limit fails it too: the declaration is stale and would skip entries that
#     fit. The scan runs on every call, whatever the paths, so the pull request that adds the use that crosses the
#     limit fails its own scope job, even when it changes only a shared file. On 2026-11-24 three counts stood at the
#     limit exactly (Button's implementation and page, Surface: 5 each), with no headroom on purpose: the next use of
#     any of them asks for the decision. ListRow stood there too, until #147 took it to 7 and the owner declared it
#     base; Button's implementation, until the pattern `empty-state` (#35) took it to 6 and the owner declared Button
#     base (2026-11-27), which cuts its page's 5 too. Surface still stands at the limit. The counts are in
#     tools/apple/audit-scope-test.sh, which pins them.
#   - Text has no directory of its own (its code is in the shared TokenAdapters.swift), so it is shared, as before.
# The snapshot matrix (WestronCatalog/Generated/, SnapshotMatrix/) and the catalog's host (the root files that declare
# no entry) are not read: they render the pages, and no entry draws them. A unit is the finest grain: an entry that
# draws a page struct reaches all it uses, so the four floating Button entries, one struct with a `part`, come
# together. What the scan cannot see is not followed, and the nightly full audit stays the net: a type named only
# through a generic parameter, a type alias or a string; a style modifier called with a variable, not a case
# (`.toggleStyle(style)`; the variable's type, named where it is declared, is usually followed instead); an
# initializer added to a system type with no labels (`init(_:)`); a name qualified by its module (`WestronUI.ListRow`).
# A catalog entry the scan does not read as a unit, or a component whose implementation it reads nothing from, fails
# the script, as an unreadable registry does.
#
#   tools/apple/audit-scope.sh --registry   prints the registry's entry names, one per line, as the script reads them
#   tools/apple/audit-scope.sh --uses       prints, for each component, what a change to its implementation and to its
#                                           page selects beyond its own entries, and through which units
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

ui=platforms/apple/Sources/WestronUI
# The contracts' vocabulary, the components' generated enums (decisions/0017): read with WestronUI.
contract=platforms/apple/Sources/WestronContract
catalog=platforms/apple/Sources/WestronCatalog
registry="$catalog/Catalog.swift"
# The limit (see "Use" above): at most this many entries beyond a component's own, one leg of the audit.
fan_out_limit=5
# The base components (see "Use" above), "<Name>: <reason>" per line.
base_components="
Button: the action of every screen, drawn on 8 other entries on 2026-11-28 (TextField's three live entries,
  color-in-use, controls and the patterns empty-state, form and errors), and its page's FlowLayout on 5 (checkbox,
  chip, color-categories, color-in-use and controls); the owner's decision of 2026-11-27 (#35)
Icon: every glyph of the catalog is an Icon, drawn on 13 other entries on 2026-11-24 (Chip, Disclosure, ListRow,
  TextField's glyphs, the color and status pages)
ListRow: the row of every list, drawn on 7 other entries on 2026-11-24 (the four floating Button entries, Disclosure,
  and Checkbox's two, whose check dims with a disabled row, #147); the owner's decision of 2026-11-24
"

note() { echo "audit-scope: $*" >&2; }

# The registry's entry names, in its order, one per line (see the rules above).
registry_names() {
  local names
  names="$(sed -n '/static let entries: \[CatalogEntry\]/,/ func /p' "$registry" |
    sed -nE 's/^ *\.([A-Za-z0-9_]+),?$/\1/p; s/^ *[A-Za-z0-9_]+\.append\(\.([A-Za-z0-9_]+)\)$/\1/p')"
  if [ -z "$names" ]; then
    echo "audit-scope: no entry read from the registry $registry: its shape changed; teach this script to read it" >&2
    return 1
  fi
  echo "$names"
}

if [ "${1:-}" = --registry ]; then
  registry_names
  exit
fi
registered="$(registry_names)"

# The entries <file> declares, "<name> <id>" per line.
declared() {
  perl -0777 -ne 'while (/static\s+let\s+(\w+)\s*=\s*CatalogEntry\(\s*id:\s*"([^"]+)"/g) { print "$1 $2\n" }' "$1"
}

# The page of the component <Name>; fails when <Name> has code in WestronUI but no page.
component_page() {
  local name="$1" page="$catalog/Components/$1Pages.swift"
  if [ -f "$page" ]; then
    echo "$page"
  elif [ -d "$ui/$name" ] || [ -f "$ui/Generated/$name+Contract.swift" ]; then
    echo "audit-scope: the component $name has code in $ui but no catalog page $page;" \
      "add its entries (Catalog.swift) or teach this script its page" >&2
    return 1
  fi
}

# The files of the pattern <Name>'s catalog directory that declare entries, one per line; nothing when there are none.
pattern_pages() {
  local file
  for file in "$catalog/Patterns/$1"/*.swift; do
    if [ -f "$file" ] && [ -n "$(declared "$file")" ]; then echo "$file"; fi
  done
}

# Whether the page <file> shares nothing with the rest of WestronCatalog (see the rules above).
self_contained() {
  local file="$1" type users
  # Captured rather than piped into `grep -q`, which may close the pipe early and fail it under pipefail.
  users="$(grep -E '^(public |internal )?extension ' "$file" | grep -vE 'extension CatalogEntry( |\{|$)' || true)"
  [ -z "$users" ] || return 1
  while IFS= read -r type; do
    users="$(grep -rlw --include='*.swift' "$type" "$catalog" | grep -vxF "$file" || true)"
    [ -z "$users" ] || return 1
  done < <(sed -nE 's/^(public |internal )?(final )?(struct|enum|class|actor|protocol) ([A-Za-z0-9_]+).*/\4/p' "$file")
}

# The names of the declared base components, one per line.
base_names() { sed -nE 's/^([A-Za-z0-9_]+):.*/\1/p' <<< "$base_components"; }

# What a change to each component selects beyond its own entries (see "Use" above), one line per component and kind
# of change, tab-separated: <Name>, impl or page, 1 for a base component (cut), the number of other entries it reaches,
# the entries it selects as "<name>:<id>" separated by spaces, and for each "<id>: <unit> -> … -> <unit>" separated by
# "; " (both "-" when none). Fails when the sources are not in the shape it reads, and at the tripwire: a component
# not declared base past the limit, or a declared one within it.
uses_table() {
  local components files
  components="$(find "$catalog/Components" -name '*Pages.swift' | sed -E 's|.*/([^/]+)Pages\.swift$|\1|' | sort)"
  files="$({
    find "$ui" "$contract" "$catalog/Components" "$catalog/Foundations" -name '*.swift'
    if [ -d "$catalog/Patterns" ]; then find "$catalog/Patterns" -name '*.swift'; fi
    for file in "$catalog"/*.swift; do
      if [ -n "$(declared "$file")" ]; then echo "$file"; fi
    done
  } | sort)"
  # shellcheck disable=SC2086 # the names and paths have no spaces
  perl - "$ui" "$contract" "$catalog" "$fan_out_limit" "$(base_names | paste -sd, -)" $components -- $files << 'PERL'
use strict;
use warnings;

my ($ui, $contract, $catalog, $limit, $base_list, @rest) = @ARGV;
my (@components, @files);
my $list = \@components;
for (@rest) {
  if ($_ eq '--') { $list = \@files; next }
  push @$list, $_;
}

sub slurp { my ($p) = @_; open my $fh, '<', $p or die "audit-scope: cannot read $p\n"; local $/; my $s = <$fh>; $s }

# A file's code without its comments and the contents of its string literals.
sub strip {
  my ($s) = @_;
  $s =~ s{("""[\s\S]*?"""|"(?:[^"\\\n]|\\.)*"|//[^\n]*|/\*[\s\S]*?\*/)}{substr($1, 0, 1) eq '/' ? ' ' : '""'}ge;
  $s
}

my $mods = qr/(?:(?:\@\w+(?:\([^()]*\))?|public|package|internal|private|fileprivate|open|static|final|nonisolated|
  mutating|indirect|override|lazy|convenience|required|dynamic|class(?=\s+(?:func|var|let)\b))\s+)*/x;
my $typekw = qr/^(?:struct|enum|class|actor|protocol|typealias)$/;
# Code inside parentheses, with parentheses nested two deep.
my $balanced = qr/(?:[^()]|\((?:[^()]|\([^()]*\))*\))/;

# A parameter list split at its top-level commas.
sub split_top {
  my ($s) = @_;
  my ($depth, $part, @parts) = (0, '');
  for my $ch (split //, $s) {
    $depth++ if $ch =~ /[(<\[]/;
    $depth-- if $ch =~ /[)>\]]/;
    if ($ch eq ',' && $depth == 0) { push @parts, $part; $part = '' } else { $part .= $ch }
  }
  (@parts, $part);
}

# Walks a file's code, calling back on each declaration, brace and other word.
sub walk {
  my ($code, $on) = @_;
  pos($code) = 0;
  while (pos($code) < length $code) {
    my $at = pos $code;
    if ($code =~ /\G([{}])/gc) {
      $on->{brace}->($1, $at);
    } elsif ($code =~ /\G($mods)(struct|enum|class|actor|protocol|extension|typealias|func|var|let|case)
      \s+([A-Za-z_][\w.]*)/gcx) {
      my ($m, $kw, $name) = ($1, $2, $3);
      my %d = (kw => $kw, name => $name, private => ($m =~ /\b(?:private|fileprivate)\b/ ? 1 : 0), at => $at);
      if ($kw eq 'func' && $code =~ /\G\s*(?:<[^{>]*>)?\s*\(\s*(?:\w+\s+)?\w+\s*:\s*(?:\@\w+\s+)?(\w+)/gc) {
        $d{param} = $1;
      } elsif ($kw eq 'case' && $code =~ /\G([^\n{}]*)/gc) {
        my $more = $1;
        $d{cases} = [$name, $more =~ /,\s*([A-Za-z_]\w*)/g];
      }
      $on->{decl}->(\%d);
    } elsif ($code =~ /\G([A-Za-z_]\w*)/gc) {
      $on->{word}->($1, $at) if $on->{word};
    } else {
      $code =~ /\G(?:[^A-Za-z_{}\@]+|\@)/gc;
    }
  }
}

my %code = map { $_ => strip(slurp($_)) } @files;

# The types the files declare at their top level.
my %own;
for my $file (@files) {
  my $depth = 0;
  walk($code{$file}, {
    brace => sub { $depth += $_[0] eq '{' ? 1 : -1 },
    decl => sub { $own{$_[0]{name}} = 1 if $depth == 0 && $_[0]{kw} =~ $typekw },
  });
}

# The units, each with the code that belongs to it.
my @units;
for my $file (@files) {
  my $code = $code{$file};
  my (@stack, $pending, $cur);
  my $last = 0;
  my $flush = sub {
    my ($to) = @_;
    $units[$cur]{text} .= substr($code, $last, $to - $last) if defined $cur;
    $last = $to;
  };
  my $unit = sub {
    my ($name, $kind, $private, $at, $member) = @_;
    $flush->($at);
    push @units, { file => $file, name => $name, kind => $kind, private => $private, member => $member, text => '' };
    $cur = $#units;
  };
  walk($code, {
    brace => sub {
      my ($brace, $at) = @_;
      if ($brace eq '}') {
        pop @stack;
        $pending = undef;
        if (!@stack) { $flush->($at + 1); $cur = undef }
        return;
      }
      my $scope = { kind => 'other' };
      if ($pending && $pending->{kw} =~ $typekw) {
        $scope = { kind => $pending->{kw}, unit => $pending->{unit} };
      } elsif ($pending && $pending->{kw} eq 'extension') {
        my $type = $pending->{name} =~ s/\..*//r;
        $scope = {
          kind => 'extension', foreign => !$own{$type}, private => $pending->{private}, name => $pending->{name},
        };
        if (!@stack) {
          # The extension's header belongs to no unit: `extension ListRowBranch` is not a use of ListRowBranch.
          $flush->($pending->{at});
          $cur = undef;
          $flush->($at + 1);
          if (!$scope->{foreign}) { $unit->($type, 'type', $pending->{private}, $at + 1); $scope->{unit} = $cur }
        }
      }
      push @stack, $scope;
      $pending = undef;
    },
    decl => sub {
      my ($d) = @_;
      my $top = $stack[-1];
      if ($d->{kw} eq 'case') {
        push @{$units[$top->{unit}]{cases}}, @{$d->{cases}} if $top && $top->{kind} eq 'enum' && defined $top->{unit};
        return;
      }
      $pending = $d;
      return if $d->{kw} eq 'extension';
      if (!@stack || (@stack == 1 && $top->{kind} eq 'extension' && $top->{foreign})) {
        my $kind = $d->{kw} =~ $typekw ? 'type' : $d->{kw} eq 'func' ? 'func' : 'var';
        $unit->($d->{name}, $kind, ($d->{private} || (@stack && $top->{private})) ? 1 : 0, $d->{at},
          @stack ? $top->{name} : undef);
        $units[$cur]{param} = $d->{param} if $d->{param};
        $d->{unit} = $cur;
      }
    },
    word => sub {
      my ($word, $at) = @_;
      return unless ($word eq 'init' || $word eq 'subscript') && @stack == 1 && $stack[0]{kind} eq 'extension'
        && $stack[0]{foreign};
      # An initializer added to a system type is a unit named by the type and the labels a call must write.
      my $type = $stack[0]{name} =~ s/.*\.//r;
      if ($word eq 'init' && substr($code, $at) =~ /^init\s*[?!]?\s*(?:<[^{>]*>)?\s*\(($balanced*)\)/) {
        my @labels = map { /^\s*(\w+)(?:\s+\w+)?\s*:[^=]*$/ && $1 ne '_' ? $1 : () } split_top($1);
        if (@labels) {
          $unit->("$type(" . join('', map { "$_:" } @labels) . ')', 'init', $stack[0]{private}, $at, $stack[0]{name});
          @{$units[$cur]}{qw(type labels)} = ($type, \@labels);
          return;
        }
      }
      $flush->($at);
      $cur = undef;
    },
  });
  $flush->(length $code);
}

# The entries, each a unit; one the units miss fails the script.
my %entry_id;
for my $file (@files) {
  my $raw = slurp($file);
  while ($raw =~ /static\s+let\s+(\w+)\s*=\s*CatalogEntry\(\s*id:\s*"([^"]+)"/g) { $entry_id{"$file $1"} = $2 }
}
my @entries = grep {
  ($units[$_]{member} // '') eq 'CatalogEntry' && exists $entry_id{"$units[$_]{file} $units[$_]{name}"}
} 0 .. $#units;
my %is_entry = map { $_ => 1 } @entries;
my %found = map { ("$units[$_]{file} $units[$_]{name}" => 1) } @entries;
for (sort keys %entry_id) {
  next if $found{$_};
  die "audit-scope: the entry $_ is not a static let in an extension of CatalogEntry as this script reads it;"
    . " teach it the new shape\n";
}

sub impl_of {    # the component whose implementation <file> is, or ''
  my ($file) = @_;
  return $1 if $file =~ m{^\Q$ui\E/([^/]+)/[^/]+\.swift$} && $1 ne 'Generated';
  return $1 if $file =~ m{^\Q$ui\E/Generated/(\w+)\+Contract\.swift$};
  return $1 if $file =~ m{^\Q$contract\E/Generated/(\w+)\+Contract\.swift$};
  return '';
}
for my $c (@components) {
  next if !grep { impl_of($_) eq $c } @files;
  next if grep { impl_of($units[$_]{file}) eq $c } 0 .. $#units;
  die "audit-scope: no declaration read from the implementation of $c; teach this script its shape\n";
}

# How code names each unit (an entry is named by the registry alone).
my %enum_cases;
for my $u (@units) { $enum_cases{$u->{name}} = $u->{cases} if $u->{cases} }
my (%named, @by_pattern);
for my $i (0 .. $#units) {
  next if $is_entry{$i};
  my $u = $units[$i];
  if ($u->{kind} eq 'init') {
    my $labels = join '', map { "$balanced*?\\b\Q$_\E\\s*:" } @{$u->{labels}};
    push @by_pattern, [$i, qr/(?<![\w.])\Q$u->{type}\E\s*\($labels/];
    next;
  }
  if ($u->{kind} eq 'func' && $u->{name} =~ /Style$/ && $u->{param} && $enum_cases{$u->{param}}) {
    my $cases = join '|', @{$enum_cases{$u->{param}}};
    push @by_pattern, [$i, qr/\b\Q$u->{name}\E\s*\(\s*(?:\Q$u->{param}\E)?\.(?:$cases)\b/];
    next;
  }
  my $kind = $u->{kind} eq 'var' && defined $u->{member} ? 'member' : $u->{kind};
  push @{$named{$kind}{$u->{name}}}, $i;
}
sub alternation {
  my $names = join '|', map { quotemeta } sort { length $b <=> length $a || $a cmp $b } keys %{$_[0] // {}};
  $names ? qr/(?:$names)/ : qr/(?!)/;
}
my %pattern = (
  type => qr/(?<![\w.])(@{[alternation($named{type})]})\b/,
  var => qr/(?<![\w.])(@{[alternation($named{var})]})\b/,
  member => qr/\.(@{[alternation($named{member})]})\b/,
  func => qr/(?<!\w)(?<!func\s)(@{[alternation($named{func})]})\s*[({<]/,
);

# The users of each unit.
my @users;
for my $i (0 .. $#units) {
  my $u = $units[$i];
  my %uses;
  for my $kind (sort keys %pattern) {
    $uses{$_} = 1 for map { @{$named{$kind}{$_}} } ($u->{text} =~ /$pattern{$kind}/g);
  }
  for (@by_pattern) { $uses{$_->[0]} = 1 if $u->{text} =~ $_->[1] }
  for my $j (sort { $a <=> $b } keys %uses) {
    next if $j == $i || ($units[$j]{private} && $units[$j]{file} ne $u->{file});
    push @{$users[$j]}, $i;
  }
}

# The entries that reach any of <seeds>, each with its path, not going on through the units of <stop>'s components.
sub reach {
  my ($seeds, $stop) = @_;
  my %from = map { $_ => -1 } @$seeds;
  my @queue = @$seeds;
  while (@queue) {
    my $i = shift @queue;
    for my $j (@{$users[$i] // []}) {
      next if exists $from{$j};
      $from{$j} = $i;
      my $c = impl_of($units[$j]{file});
      push @queue, $j unless $c ne '' && $stop->{$c};
    }
  }
  my %path;
  for my $e (grep { exists $from{$_} } @entries) {
    my @chain;
    for (my $i = $from{$e}; $i >= 0; $i = $from{$i}) { push @chain, $units[$i]{name} }
    $path{$e} = join ' -> ', @chain;
  }
  \%path;
}

# The declared base components cut; past the limit, any other fails the script with the decision to make.
my %base = map { $_ => 1 } grep { $_ ne '' } split /,/, $base_list;
my %is_component = map { $_ => 1 } @components;
my @errors;
for (sort keys %base) {
  push @errors, "audit-scope: $_ is declared a base component (base_components) but has no catalog page; remove it"
    unless $is_component{$_};
}
my $id = sub { $entry_id{"$units[$_[0]]{file} $units[$_[0]]{name}"} };
for my $c (@components) {
  my $page = "$catalog/Components/${c}Pages.swift";
  my %seeds = (
    impl => [grep { impl_of($units[$_]{file}) eq $c } 0 .. $#units],
    page => [grep { $units[$_]{file} eq $page } 0 .. $#units],
  );
  my %own = map { $_ => 1 } grep { $units[$_]{file} eq $page } @entries;
  my %stop = map { $_ => 1 } grep { $_ ne $c } keys %base;
  for my $kind (qw(impl page)) {
    my $path = reach($seeds{$kind}, \%stop);
    my @extra = grep { exists $path->{$_} && !$own{$_} } @entries;
    my $fan = @extra;
    my $ids = join ',', map { $id->($_) } @extra;
    if ($base{$c}) {
      push @errors, "audit-scope: $c is declared a base component (base_components), but a change to it would select"
        . " only $fan entries beyond its own (" . ($ids || "none") . "), within the limit of $limit: the"
        . " declaration is stale and skips entries that fit; remove $c from base_components in"
        . " tools/apple/audit-scope.sh"
        if $kind eq 'impl' && $fan <= $limit;
      @extra = ();
    } elsif ($fan > $limit && $kind eq 'impl') {
      push @errors, "audit-scope: a change to $c would select $fan entries beyond its own, more than the limit of"
        . " $limit (fan_out_limit, one leg of the audit): $ids. Decide, in tools/apple/audit-scope.sh: declare $c a"
        . " base component (base_components, with its reason), so that its changes audit its own entries only and the"
        . " others wait for the nightly run; or raise fan_out_limit and accept larger audits on its pull requests";
    } elsif ($fan > $limit) {
      push @errors, "audit-scope: a change to the page ${c}Pages.swift would select $fan entries beyond its own,"
        . " which use its code, more than the limit of $limit (fan_out_limit, one leg of the audit): $ids. Decide:"
        . " move the code they share out of the page into a shared file of the catalog (Foundations/), whose changes"
        . " wait for the nightly run; declare $c a base component (base_components in tools/apple/audit-scope.sh);"
        . " or raise fan_out_limit and accept larger audits";
    }
    print join("\t", $c, $kind, $base{$c} ? 1 : 0, $fan,
      (join(' ', map { "$units[$_]{name}:" . $id->($_) } @extra) || '-'),
      (join('; ', map { $id->($_) . ": $path->{$_}" } @extra) || '-')), "\n";
  }
}
die join("\n", @errors) . "\n" if @errors;
PERL
}

# The scan runs on every call, whatever the paths, so that the tripwire fires on the pull request that crosses it.
if ! table="$(uses_table)"; then exit 1; fi

if [ "${1:-}" = --uses ]; then
  while IFS=$'\t' read -r name kind cut fan entries paths; do
    if [ "$cut" = 1 ]; then
      echo "$name $kind: 0 (base component; $fan other entries draw it, nightly only)"
    elif [ "$entries" = - ]; then
      echo "$name $kind: 0"
    else
      echo "$name $kind: $fan: $(tr ' ' '\n' <<< "$entries" | cut -d: -f2 | paste -sd, -)"
      tr ';' '\n' <<< "$paths" | sed -E 's/^ *(.*)/    \1/'
    fi
  done <<< "$table"
  exit
fi

pages="" uses=""
while IFS= read -r path || [ -n "$path" ]; do
  [ -n "$path" ] || continue
  page="" why="shared or outside the catalog" use=""
  case "$path" in
    "$ui"/Generated/*+Contract.swift | "$contract"/Generated/*+Contract.swift)
      name="${path##*/}"
      page="$(component_page "${name%+Contract.swift}")"
      use="${name%+Contract.swift} impl"
      ;;
    "$catalog"/Generated/ComponentMatrix+All.swift) ;;
    "$catalog"/Generated/*+Matrix.swift)
      name="${path##*/}"
      page="$(component_page "${name%+Matrix.swift}")"
      ;;
    "$ui"/Generated/* | "$ui"/Fonts/* | "$ui"/*.xcassets/*) ;;
    "$ui"/*/*)
      name="${path#"$ui"/}"
      page="$(component_page "${name%%/*}")"
      use="${name%%/*} impl"
      ;;
    "$catalog"/Components/*Pages.swift)
      page="$path"
      name="${path##*/}"
      use="${name%Pages.swift} page"
      ;;
    spec/components/*/*)
      id="${path#spec/components/}"
      id="${id%%/*}"
      name="$(perl -pe 's/(?:^|-)(\w)/\u$1/g' <<< "$id")"
      page="$(component_page "$name")"
      use="$name impl"
      [ -n "$page" ] || why="the contract $id has no catalog page: not implemented on Apple yet"
      ;;
    # Before the root's files below, whose pattern `*` would match a path in a subdirectory.
    spec/patterns/*.md | "$catalog"/Patterns/*/*)
      if [ "${path#spec/patterns/}" != "$path" ]; then
        id="${path#spec/patterns/}"
        name="$(perl -pe 's/(?:^|-)(\w)/\u$1/g' <<< "${id%.md}")"
      else
        name="${path#"$catalog"/Patterns/}"
        name="${name%%/*}"
      fi
      page="$(pattern_pages "$name")"
      [ -n "$page" ] || why="the pattern has no entry in $catalog/Patterns/$name: no Apple example in the catalog yet"
      ;;
    "$catalog"/Foundations/*.swift | "$catalog"/*.swift)
      if [ -f "$path" ] && [ -n "$(declared "$path")" ] && self_contained "$path"; then
        page="$path"
      fi
      ;;
  esac
  # A pattern's directory may give several pages, one per line.
  if [ -n "$page" ] && [ -f "${page%%$'\n'*}" ]; then
    note "$path → $(while IFS= read -r file; do declared "$file"; done <<< "$page" | cut -d' ' -f2 | paste -sd, -)"
    pages+="$page"$'\n'
    if [ -n "$use" ]; then uses+="$use"$'\n'; fi
  elif [ -z "$page" ]; then
    note "$path → nothing on a pull request: $why"
  else
    note "$path → its page $page is gone: nothing"
  fi
done

# The entries that draw what changed (see "Use" above), "<name> <id>" per line.
drawn=""
uses="$(sort -u <<< "$uses" | sed '/^$/d')"
if [ -n "$uses" ]; then
  while read -r name kind; do
    what="$name is" verb="drawn on"
    [ "$kind" = impl ] || what="the code of ${name}Pages.swift is" verb="used by"
    while IFS=$'\t' read -r _ _ cut fan entries _; do
      if [ "$cut" = 1 ]; then
        note "$name is a base component (base_components in this script): only its own" \
          "entries here; the others wait for the nightly run"
      elif [ "$entries" != - ]; then
        note "$what also $verb $(tr ' ' '\n' <<< "$entries" | cut -d: -f2 | paste -sd, -)"
        drawn+="$(tr ' ' '\n' <<< "$entries" | tr ':' ' ')"$'\n'
      fi
    done < <(awk -F'\t' -v name="$name" -v kind="$kind" '$1 == name && $2 == kind' <<< "$table")
  done <<< "$uses"
fi

# The ids of the pages' entries and of the entries that draw them, in the registry's order.
ids=""
if [ -n "$pages" ]; then
  wanted="$({
    sort -u <<< "$pages" | sed '/^$/d' | while IFS= read -r page; do declared "$page"; done
    echo "$drawn"
  } | sed '/^$/d' | sort -u)"
  while IFS= read -r name; do
    id="$(awk -v name="$name" '$1 == name { print $2 }' <<< "$wanted")"
    if [ -n "$id" ]; then ids+="${ids:+,}$id"; fi
  done <<< "$registered"
  while IFS= read -r name; do
    grep -qxF "$name" <<< "$registered" ||
      note "the entry $name is not in the registry ($registry), so it is not audited"
  done < <(cut -d" " -f1 <<< "$wanted")
fi
echo "$ids"
