require "open3"

class Buck < Formula
  @@buck_version = "2016.03.28.01"
  desc "The Buck build system"
  homepage "https://buckbuild.com/"
  head "https://github.com/facebook/buck.git"
  version @@buck_version
  url "https://api.github.com/repos/facebook/buck/tarball/v2016.03.28.01"
  sha256 "cfa5f3c1177e368f8a4d624520e53baf9cf36abb0657a5414a48684380912ccc"

  bottle do
    root_url "https://github.com/facebook/buck/releases/download/v#{@@buck_version}"
    cellar :any_skip_relocation
    sha256 "c2937782ea161f92c438d2951b21acaa632380f2ea80ed25b5b7cd16863e6211" => :yosemite_or_later
  end

  depends_on :java => "1.7+"
  depends_on :ant

  def install
    # First, bootstrap the build by building Buck with Apache Ant.
    system "ant"
    # Mark the build as successful.
    File.open("build/successful-build", "w") {}
    # Now, build the Buck PEX archive with the Buck bootstrap.
    system "./bin/buck", "build", "buck"
    mkdir_p "#{bin}"
    ohai "Finding PEX archive..."
    stdout, stderr, status = Open3.capture3("./bin/buck", "targets", "--show_output", "buck")
    if status == 0
      stdout.chomp!
      _, path = stdout.split(" ", 2)
      ohai "Installing buck in #{bin}/buck..."
      cp(path, "#{bin}/buck", :preserve => true)
      ohai "Done."
    else
      onoe "Could not find location of built buck: " + stderr
    end
  end

  test do
    ohai "Setting up Buck repository in " + testpath
    (testpath/".buckconfig").write("")
    (testpath/"BUCK").write("cxx_binary(name = 'foo', srcs = ['foo.c'])")
    (testpath/"foo.c").write("#include <stdio.h>\nint main(int argc, char **argv) { printf(\"Hello world!\\n\"); }\n")
    ohai "Building and running C binary..."
    stdout, stderr, status = Open3.capture3("#{bin}/buck", "run", ":foo")
    stdout.chomp!
    ohai "Got output from binary: " + stdout
    assert_equal 0, status
    assert_equal "Hello world!", stdout
    ohai "Test complete."
  end
end