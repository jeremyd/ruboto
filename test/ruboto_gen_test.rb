require File.expand_path("test_helper", File.dirname(__FILE__))
require 'bigdecimal'
require 'test/app_test_methods'

class RubotoGenTest < Test::Unit::TestCase
  include AppTestMethods

  def setup
    generate_app
  end

  def teardown
    cleanup_app
  end

  def test_icons_are_updated
    Dir.chdir APP_DIR do
      assert_equal 4032, File.size('res/drawable-hdpi/ic_launcher.png')
      assert_equal 2548, File.size('res/drawable-mdpi/ic_launcher.png')
      assert_equal 1748, File.size('res/drawable-ldpi/ic_launcher.png')
    end
  end

  def test_gen_class_activity_with_lowercase_should_fail
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen class activity --name VeryNewActivity"
      assert_equal 1, $?.exitstatus
      assert !File.exists?('src/org/ruboto/test_app/VeryNewActivity.java')
      assert !File.exists?('src/very_new_activity.rb')
      assert !File.exists?('test/src/very_new_activity_test.rb')
      assert File.read('AndroidManifest.xml') !~ /VeryNewActivity/
    end
  end

  def test_new_apk_size_is_within_limits
    apk_size = BigDecimal(File.size("#{APP_DIR}/bin/RubotoTestApp-debug.apk").to_s) / 1024
    version = "  PLATFORM: #{RUBOTO_PLATFORM}"
    version << ", ANDROID_TARGET: #{ANDROID_TARGET}"
    if RUBOTO_PLATFORM == 'STANDALONE'
      upper_limit = {
          '1.6.7' => 5800.0,
          '1.7.0.preview1' => ANDROID_TARGET < 15 ? 7062.0 : 7308.0,
          '1.7.0.preview2.dev' => ANDROID_TARGET < 15 ? 7062.0 : 7308.0,
      }[JRUBY_JARS_VERSION.to_s] || 4200.0
      version << ", JRuby: #{JRUBY_JARS_VERSION.to_s}"
    else
      upper_limit = {
          7 => 62.0,
          10 => 63.0,
          15 => 66.0,
      }[ANDROID_TARGET] || 64.0
    end
    lower_limit = upper_limit * 0.9
    assert apk_size <= upper_limit, "APK was larger than #{'%.1f' % upper_limit}KB: #{'%.1f' % apk_size.ceil(1)}KB.#{version}"
    assert apk_size >= lower_limit, "APK was smaller than #{'%.1f' % lower_limit}KB: #{'%.1f' % apk_size.floor(1)}KB.  You should lower the limit.#{version}"
  end

end
