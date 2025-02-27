require "test_helper"

class RQRCodeCore::BaseTest < Minitest::Test
  require_relative "data"

  def test_no_data_given
    assert_raises(RQRCodeCore::QRCodeArgumentError) {
      RQRCodeCore::QRCode.new(size: 1, level: :h)
      RQRCodeCore::QRCode.new(size: 1)
      RQRCodeCore::QRCode.new
    }

    assert_raises(RQRCodeCore::QRCodeRunTimeError) {
      qr = RQRCodeCore::QRCode.new("duncan")
      qr.checked?(0, 999999)
    }
  end

  def test_H_
    qr = RQRCodeCore::QRCode.new("duncan", size: 1)

    assert_equal qr.modules.size, 21
    assert_equal qr.modules, MATRIX_1_H

    qr = RQRCodeCore::QRCode.new("duncan", size: 1)
    assert_equal qr.modules, MATRIX_1_H
    qr = RQRCodeCore::QRCode.new("duncan", size: 1, level: :l)
    assert_equal qr.modules, MATRIX_1_L
    qr = RQRCodeCore::QRCode.new("duncan", size: 1, level: :m)
    assert_equal qr.modules, MATRIX_1_M
    qr = RQRCodeCore::QRCode.new("duncan", size: 1, level: :q)
    assert_equal qr.modules, MATRIX_1_Q
  end

  def test_3_H_
    qr = RQRCodeCore::QRCode.new("duncan", size: 3)

    assert_equal qr.modules.size, 29
    assert_equal qr.modules, MATRIX_3_H
  end

  def test_5_H_
    qr = RQRCodeCore::QRCode.new("duncan", size: 5)

    assert_equal qr.modules.size, 37
    assert_equal qr.modules, MATRIX_5_H
  end

  def test_10_H_
    qr = RQRCodeCore::QRCode.new("duncan", size: 10)

    assert_equal qr.modules.size, 57
    assert_equal qr.modules, MATRIX_10_H
  end

  def test_4_H_
    qr = RQRCodeCore::QRCode.new("www.bbc.co.uk/programmes/b0090blw", level: :l, size: 4)
    assert_equal qr.modules, MATRIX_4_L
    qr = RQRCodeCore::QRCode.new("www.bbc.co.uk/programmes/b0090blw", level: :m, size: 4)
    assert_equal qr.modules, MATRIX_4_M
    qr = RQRCodeCore::QRCode.new("www.bbc.co.uk/programmes/b0090blw", level: :q, size: 4)
    assert_equal qr.modules, MATRIX_4_Q

    qr = RQRCodeCore::QRCode.new("www.bbc.co.uk/programmes/b0090blw")
    assert_equal qr.modules.size, 33
    assert_equal qr.modules, MATRIX_4_H
  end

  def test_to_s
    qr = RQRCodeCore::QRCode.new("duncan", size: 1)
    assert_equal "xxxxxxx xx x  xxxxxxx\n", qr.to_s[0..21]
    assert_equal "qqqqqqqnqqnqnnqqqqqqq\n", qr.to_s(dark: "q", light: "n")[0..21]
    assert_equal "@@@@@@@ @@ @  @@@@@@@\n", qr.to_s(dark: "@")[0..21]
  end

  def test_auto_alphanumeric
    # Overflowws without the alpha version
    assert RQRCodeCore::QRCode.new("1234567890", size: 1, level: :h)

    qr = RQRCodeCore::QRCode.new("DUNCAN", size: 1, level: :h)
    assert_equal "xxxxxxx xxx   xxxxxxx\n", qr.to_s[0..21]
  end

  def test_auto_numeric
    # When digit only automatically uses numeric mode, default ecc level is :h
    digits = RQRCodeCore::QRCode.new("1" * 17) # Version 1, numeric mode, ECC h
    assert_equal 1, digits.version
    assert_equal :mode_number, digits.mode
    assert_equal :h, digits.error_correction_level
    # When alpha automatically works
    alpha = RQRCodeCore::QRCode.new("X" * 10) # Version 1, alpha mode, ECC h
    assert_equal 1, alpha.version
    assert_equal :mode_alpha_numk, alpha.mode
    assert_equal :h, alpha.error_correction_level
    # Generic should use binary
    binary = RQRCodeCore::QRCode.new("x" * 7) # Version 1, 8bit mode, ECC h
    assert_equal 1, binary.version
    assert_equal :mode_8bit_byte, binary.mode
    assert_equal :h, binary.error_correction_level
  end

  def test_numeric_2_M
    data = "279042272585972554922067893753871413584876543211601021503002"

    qr = RQRCodeCore::QRCode.new(data, size: 2, level: :m, mode: :number)
    assert_equal "xxxxxxx   x x x   xxxxxxx\n", qr.to_s[0..25]
  end

  def test_rszf_error_not_thrown
    assert RQRCodeCore::QRCode.new("2 1058 657682")
    assert RQRCodeCore::QRCode.new("40952", size: 1, level: :h)
    assert RQRCodeCore::QRCode.new("40932", size: 1, level: :h)
  end

  def test_exceed_max_size
    assert_raises RQRCodeCore::QRCodeArgumentError do
      RQRCodeCore::QRCode.new("duncan", size: 41)
    end
  end

  def test_error_correction_level
    # attr_reader was wrong
    assert_equal RQRCodeCore::QRCode.new("a", level: :h).error_correction_level, :h
  end

  def test_version_table
    # tables in RQRCodeCore::QRCode::QRMAXDIGITS wasn't updated to support greater versions
    assert_equal RQRCodeCore::QRCode.new("1" * 289, level: :h, mode: :number).version, 11
    assert_equal RQRCodeCore::QRCode.new("A" * 175, level: :h, mode: :alphanumeric).version, 11
    assert_equal RQRCodeCore::QRCode.new("a" * 383, level: :h, mode: :byte_8bit).version, 21
  end

  def test_levels
    assert RQRCodeCore::QRCode.new("duncan", level: :l)
    assert RQRCodeCore::QRCode.new("duncan", level: :m)
    assert RQRCodeCore::QRCode.new("duncan", level: :q)
    assert RQRCodeCore::QRCode.new("duncan", level: :h)

    %w[a b c d e f g i j k n o p r s t u v w x y z].each do |ltr|
      assert_raises(RQRCodeCore::QRCodeArgumentError) {
        RQRCodeCore::QRCode.new("duncan", level: ltr.to_sym)
      }
    end
  end

  def test_utf8
    qr = RQRCodeCore::QRCode.new("тест")
    assert_equal qr.modules, MATRIX_UTF8_RU_TEST
  end
end
