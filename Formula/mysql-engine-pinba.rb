require File.expand_path("../../Abstract/abstract-engine-pinba", __FILE__)

class MysqlEnginePinba < AbstractEnginePinba
  init

  resource "mysql" do
    url "http://cdn.mysql.com/Downloads/MySQL-5.6/mysql-5.6.21.tar.gz"
    sha1 "be068ba90953aecdb3f448b4ba1d35796eb799eb"
  end

  resource "master" do
    url 'https://github.com/tony2001/pinba_engine/archive/master.tar.gz'
    sha1 '07f5640339e96487630b0617a7283b6f28c7697c'
  end

  def install
    resource("mysql").stage do
      system "/usr/local/bin/cmake -DBUILD_CONFIG=mysql_release -Wno-dev && cd include && make"
      cp_r pwd, buildpath/"mysql"
    end

    resource("master").stage do
      cp_r "scripts", buildpath/"scripts"
    end

    system "./configure", "--prefix=#{prefix}",
                          "--libdir=#{prefix}/plugin",
                          "--with-mysql=#{buildpath}/mysql",
                          "--with-protobuf=#{Formula['protobuf'].opt_prefix}",
                          "--with-judy=#{Formula['judy'].opt_prefix}",
                          "--with-event=#{Formula['libevent'].opt_prefix}"

    system "make"
    system "make install"

    # Install plugin
    plugin_dir = Formula['mysql'].lib/"plugin";
    plugin_file = "#{plugin_dir}/libpinba_engine.so"
    system "if [ -L \"#{plugin_file}\" ]; then rm -f \"#{plugin_file}\"; fi"

    plugin_dir.install_symlink prefix/"plugin/libpinba_engine.so"
    system "cp -R \"#{buildpath}/default_tables.sql\" #{prefix}"
    system "cp -R \"#{buildpath}/scripts\" #{prefix}/"
  end
end
