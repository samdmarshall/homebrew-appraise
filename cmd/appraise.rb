require "formula"
require "formula_info"
require "cli/parser"

module Homebrew
  module_function

  def appraise_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `appraise` [<options>] [<formula>]

        Appraise all installed packages.

        If a formula name is provided, the individual installation will be appraised to see if the installation still has a formula available locally.
      EOS
      switch "--all",
             description: "run appraisal on all installed formulae."

      hide_from_man_page!
      named_args :formula
    end
  end

  def appraise
    args = appraise_args.parse

    # Unbrewed uses the PREFIX, which will exist
    # Things below use the CELLAR, which doesn't until the first formula is installed.
    unless HOMEBREW_CELLAR.exist?
      raise NoSuchKegError, args.named.first if args.named.present?

      return
    end

    appraisal_list = Pathname.new(HOMEBREW_CELLAR).subdirs.sort_by { |p| p.to_s.downcase }
    if not args.all?
      appraisal_list = args.named.to_resolved_formulae
    end

    appraisal_list.each do |formula|
      if formula.is_a?(Formula)
        formula = Pathname.new(HOMEBREW_CELLAR).join(formula.name)
      end
      name = formula.basename

      formula.subdirs.each do |version|
        version_number = version.basename
        path = version.join("INSTALL_RECEIPT.json")
        receipt = JSON.parse(IO.read(path))
        formula_file = receipt["source"]["path"]
        if not formula_file.nil?
          if not Pathname.new(formula_file).exist?
            ohai "#{name} @ #{version_number}"
            puts formula_file
          end
        else
          ohai "#{name} @ #{version_number}"
          puts "Needs reinstall, the existing receipt is incomplete!"
        end
      end
    end
  end
end
