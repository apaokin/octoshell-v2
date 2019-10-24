require 'rubygems'
require 'write_xlsx'
workbook = WriteXLSX.new("fields.xlsx")

 worksheet = workbook.add_worksheet('fields')
 worksheet.write(0, 0, 'ID')
 worksheet.write(0, 1, 'Название')
 worksheet.write(0, 2, 'Подсказка')
 worksheet.write(0, 3, 'Преобразовать в')
 worksheet.write(0, 4, 'Тип')
 worksheet.write(0, 5, 'Опции(если нужны)')

Support::Field.all.each_with_index do |field, index|
  worksheet.write(1 + index, 0, field.id)
  worksheet.write(1 + index, 1, field.name)
  worksheet.write(1 + index, 2, field.hint)

end
workbook.close
