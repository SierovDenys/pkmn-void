# ==============================================================================
# RGSS/RPG stubs — минимум, чтобы читать и писать .rxdata обычным Ruby.
#
# Использование:
#   ruby -r./.development/tools/rgss_stubs -e "ts = load_rxdata('Data/Tilesets.rxdata'); ..."
# или
#   require_relative 'rgss_stubs'   (из соседнего скрипта в tools/)
#
# .rxdata — это просто Marshal (версия 4.8). Проблема лишь в том, что внутри
# лежат объекты классов RPG::* и Table, которых в обычном Ruby нет. Здесь они
# восстанавливаются: RPG::* автоматически через const_missing, Table честной
# реализацией _load/_dump, потому что это userdef-объект с бинарным payload.
# ==============================================================================

# Даёт объекту-заглушке любые геттеры/сеттеры по именам его ivar'ов.
# ВАЖНО: отвечать true на любое имя нельзя. Marshal.dump проверяет
# respond_to?(:marshal_dump) и respond_to?(:_dump); если сказать "да", он вызовет
# их через method_missing, получит nil и запишет вместо объекта пустышку.
# Поэтому геттер существует только тогда, когда существует сам ivar.
module AnyAttr
  def method_missing(name, *args)
    n = name.to_s
    if n.end_with?("=")
      instance_variable_set("@#{n.chomp('=')}", args.first)
    elsif instance_variable_defined?("@#{n}")
      instance_variable_get("@#{n}")
    else
      super
    end
  end

  def respond_to_missing?(name, _priv = false)
    n = name.to_s
    n.end_with?("=") || instance_variable_defined?("@#{n}")
  end
end

module RPG; end

# Создаёт класс-заглушку по полному имени ("RPG::Event::Page"), включая
# промежуточные уровни.
#
# Через const_missing это не работает: Marshal резолвит классы через
# rb_path2class, который бросает исключение напрямую и хук не вызывает.
# Поэтому классы создаются реактивно — по имени из текста ошибки.
def define_stub_class(path, superclass = nil)
  parts = path.split("::")
  parent = Object
  parts.each_with_index do |part, idx|
    if parent.const_defined?(part, false)
      parent = parent.const_get(part, false)
    else
      leaf = (idx == parts.size - 1)
      klass = (leaf && superclass) ? Class.new(superclass) : Class.new { include AnyAttr }
      parent.const_set(part, klass)
      parent = klass
    end
  end
  parent
end

# Marshal пишет подклассы встроенных типов через маркер "C:<имя><тип>"
# (например PBAnimation < Array в PkmnAnimations.rxdata). Такие классы нельзя
# создать реактивно по тексту ошибки — она не содержит имени ("dump format
# error (user class)"). Поэтому сканируем поток заранее.
USER_CLASS_BASES = { "[" => Array, "{" => Hash, '"' => String }.freeze

def predefine_user_classes(data)
  i = 0
  while (i = data.index("C:".b, i))
    len = data.getbyte(i + 2).to_i - 5
    if len.positive? && len < 60
      name = data[i + 3, len]
      base = USER_CLASS_BASES[data[i + 3 + len]]
      if base && name&.match?(/\A[A-Z]\w*(::[A-Z]\w*)*\z/) && !Object.const_defined?(name)
        define_stub_class(name, base)
      end
    end
    i += 2
  end
end

# ------------------------------------------------------------------------------
# Table — 1/2/3-мерный массив uint16. Формат payload:
#   5 x int32 little-endian: dim, xsize, ysize, zsize, total
#   затем total x uint16 little-endian
# ------------------------------------------------------------------------------
class Table
  attr_reader :dim, :xsize, :ysize, :zsize, :data

  def initialize(xsize, ysize = 1, zsize = 1)
    @dim = (zsize > 1) ? 3 : ((ysize > 1) ? 2 : 1)
    @xsize, @ysize, @zsize = xsize, ysize, zsize
    @data = Array.new(xsize * ysize * zsize, 0)
  end

  def self._load(str)
    dim, xsize, ysize, zsize, total = str[0, 20].unpack("l<5")
    t = allocate
    t.instance_variable_set(:@dim, dim)
    t.instance_variable_set(:@xsize, xsize)
    t.instance_variable_set(:@ysize, ysize)
    t.instance_variable_set(:@zsize, zsize)
    t.instance_variable_set(:@data, str[20, total * 2].unpack("S<#{total}"))
    t
  end

  def _dump(_depth = 0)
    [@dim, @xsize, @ysize, @zsize, @data.size].pack("l<5") + @data.pack("S<*")
  end

  def [](x, y = 0, z = 0)
    @data[x + (y * @xsize) + (z * @xsize * @ysize)]
  end

  def []=(*args)
    value = args.pop
    x, y, z = args[0], args[1] || 0, args[2] || 0
    @data[x + (y * @xsize) + (z * @xsize * @ysize)] = value
  end

  # Меняет xsize с сохранением данных по координатам (нужно для сдвига тайлсетов).
  def resize_x(new_xsize)
    raise "only 1D tables supported" if @dim != 1
    d = @data.dup
    d = d[0, new_xsize] if new_xsize < d.size
    d += Array.new(new_xsize - d.size, 0) if new_xsize > d.size
    @xsize = new_xsize
    @data = d
    self
  end

  def to_s = "#<Table #{@dim}D #{@xsize}x#{@ysize}x#{@zsize}>"
  alias inspect to_s
end

# Color / Tone — тоже userdef, 4 x double little-endian.
[["Color", %i[red green blue alpha]], ["Tone", %i[red green blue gray]]].each do |name, fields|
  Object.const_set(name, Class.new do
    attr_accessor(*fields)
    define_method(:initialize) { |a = 0, b = 0, c = 0, d = 0| [a, b, c, d].each_with_index { |v, i| instance_variable_set("@#{fields[i]}", v) } }
    define_singleton_method(:_load) do |str|
      obj = allocate
      str.unpack("E4").each_with_index { |v, i| obj.instance_variable_set("@#{fields[i]}", v) }
      obj
    end
    define_method(:_dump) { |_d = 0| fields.map { |f| instance_variable_get("@#{f}") || 0 }.pack("E4") }
  end)
end

# ------------------------------------------------------------------------------
# Хелперы
# ------------------------------------------------------------------------------
def load_rxdata(path)
  data = File.binread(path)
  predefine_user_classes(data)
  defined_now = []
  loop do
    begin
      return Marshal.load(data)
    rescue ArgumentError => e
      name = e.message[/undefined class\/module (\S+)/, 1]
      raise if name.nil? || defined_now.include?(name)
      defined_now << name
      define_stub_class(name.sub(/::\z/, ""))
    end
  end
end

# Пишет через временный файл + бэкап, чтобы не потерять данные при сбое.
def save_rxdata(path, obj, backup: true)
  if backup && File.exist?(path)
    bak = "#{path}.bak"
    File.binwrite(bak, File.binread(path)) if !File.exist?(bak)
  end
  tmp = "#{path}.tmp"
  File.open(tmp, "wb") { |f| Marshal.dump(obj, f) }
  # Проверяем, что записанное читается обратно
  File.open(tmp, "rb") { |f| Marshal.load(f) }
  File.delete(path) if File.exist?(path)
  File.rename(tmp, path)
  path
end
