import telebot
from telebot import types
from pathlib import Path
import matlab.engine

while True:
  try:

      flag_file_save = 0
      eng = matlab.engine.start_matlab()

      bot = telebot.TeleBot('5346538958:AAFyTExiiUjRIp8ErfAQncv3_JbVK84i8W4');

      your_video = 0
      video_send = 0
      video_webcam = 0
      param = 0


      @bot.message_handler(commands=["start"])
      def start(message):
          bot.send_message(message.from_user.id,
                           'Привет!\n \nЯ бот - результат проекта по разработке программы распознавания подвижных объектов в интеллектуальных оптико-электронных '
                           'системах оперативного мониторинга.\n \n'
                           'Выполнен студенткой группы 4841 Санкт-Петербургского университета аэрокосмического приборостроения Афанасьевой В.И.'
                           '\n\nПрограммный код по распознаванию  и стабилизации видеопоследовательности использованный  в данном проекте '
                           'написан на языке MATLAB, после чего интегрирован в среду Python. Сам бот написан на языке Python.\n\n'
                           'Мои возможности:\n'
                           '1. Детектирование объектов\n'
                           '2. Детектирование объектов с предварительной стабилизацией\n'
                           '3. Стабилизация видеопоследовательности\n'
                           'Источники видео:\n'
                           '1. Получение видео с камеры в режиме реального времени\n'
                           '2. Получение видеопоследовательности от пользователя\n\n'
                           'Чтобы начать напиши /go \nПриятного использования!')


      @bot.message_handler(content_types=['text'])
      def handle_text(message):
          global flag_file_save
          global src_name
          global param
          global det

          if message.text == '/go':
              keyboard = types.ReplyKeyboardMarkup(resize_keyboard=True)  # наша клавиатура
              item1 = types.KeyboardButton("Мое видео")
              item2 = types.KeyboardButton("Видео с веб-камеры")
              keyboard.add(item1)
              keyboard.add(item2)
              bot.send_message(message.from_user.id, text='Какое видео Вы хотите обработать?', reply_markup=keyboard)
          elif message.text.strip() == 'Мое видео':
              handle_docs_photo(message)
          elif message.text.strip() == 'Видео с веб-камеры':
              bot.reply_to(message, text='Функционал временно отключен.',
                           reply_markup=0)
          elif message.text.strip() == 'Детектирование' and flag_file_save == 1:

              det = 1
              keyboard = types.ReplyKeyboardMarkup(resize_keyboard=True)  # наша клавиатура
              item1 = types.KeyboardButton("Да, ввести свои параметры")
              item2 = types.KeyboardButton("Нет, оставить параметры по умолчанию")
              keyboard.add(item1)
              keyboard.add(item2)
              msg = bot.send_message(message.from_user.id, text='Хотите обновить параметры для детектирования?',
                                     reply_markup=keyboard)
              bot.register_next_step_handler(msg, AnswerParam)

          elif message.text.strip() == 'Детектирование со стабилизацией' and flag_file_save == 1:

              det = 0
              keyboard = types.ReplyKeyboardMarkup(resize_keyboard=True)  # наша клавиатура
              item1 = types.KeyboardButton("Да, ввести свои параметры")
              item2 = types.KeyboardButton("Нет, оставить параметры по умолчанию")
              keyboard.add(item1)
              keyboard.add(item2)
              msg = bot.send_message(message.from_user.id, text='Хотите обновить параметры для детектирования?', reply_markup=keyboard)
              bot.register_next_step_handler(msg, AnswerParam)
          elif message.text.strip() == 'Стабилизация' and flag_file_save == 1:
              keyboard = types.ReplyKeyboardMarkup(resize_keyboard=True)  # наша клавиатура
              item1 = types.KeyboardButton("Продолжить")
              keyboard.add(item1)
              msg = bot.send_message(message.from_user.id, text='Чтобы начать процесс нажмите Продолжить', reply_markup=keyboard)
              bot.register_next_step_handler(msg, stabl)
          else:
              bot.send_message(message.from_user.id,
                               text='Такой команды не существует. Чтобы обработать видео введите /go!')

      def AnswerParam(message):
          if message.text == 'Да, ввести свои параметры':
              msg = bot.send_message(message.chat.id, 'Введите минимальный размер области:')
              bot.register_next_step_handler(msg, MinimumBlobArea)
          elif message.text == 'Нет, оставить параметры по умолчанию':
              global param
              param = 0
              keyboard = types.ReplyKeyboardMarkup(resize_keyboard=True)  # наша клавиатура
              item1 = types.KeyboardButton("Продолжить")
              keyboard.add(item1)
              msg = bot.send_message(message.from_user.id, text='Вы выбрали параметры по умолчанию! Чтобы начать процесс нажмите Продолжить.',
                                     reply_markup=keyboard)
              global det
              if det == 0:
                  bot.register_next_step_handler(msg, detect_stabl)
              else:
                  bot.register_next_step_handler(msg, detect)


      def MinimumBlobArea(message):
          global MinBlobArea
          MinBlobArea = message.text
          bot.register_next_step_handler(bot.send_message(message.chat.id, 'Введите максимальный размер области:'), MaximumBlobArea)

      def MaximumBlobArea(message):
          global MaxBlobArea
          MaxBlobArea = message.text
          bot.register_next_step_handler(bot.send_message(message.chat.id, 'Введите размер области для морфологического открытия:'), imopen_streal)

      def imopen_streal(message):
          global imop_streal
          imop_streal = message.text
          bot.register_next_step_handler(bot.send_message(message.chat.id, 'Введите размер области для морфологического закрытия:'), imclose_streal)

      def imclose_streal(message):
          global imcl_streal
          imcl_streal = message.text

          bot.send_message(message.from_user.id, text='Вы ввели следующие параметры:'
                                                      '\nМинимальный размер области - ' + str(MinBlobArea) +
                                                      '\nМаксимальный размер области - ' + str(MaxBlobArea) +
                                                      '\nРазмер области для морфологического открытия - ' + str(imop_streal) +
                                                      '\nРазмер области для морфологического закрытия - ' + str(imcl_streal))
          global param
          param = 1
          keyboard = types.ReplyKeyboardMarkup(resize_keyboard=True)  # наша клавиатура
          item1 = types.KeyboardButton("Продолжить")
          keyboard.add(item1)
          msg = bot.send_message(message.from_user.id, text='Чтобы начать процесс нажмите Продолжить',
                                 reply_markup=keyboard)
          bot.register_next_step_handler(msg, detect_stabl)

      def detect(message):
          global param
          bot.reply_to(message, text='Началось детектирование объектов на '
                                     'вашей видеопоследовательности.\nЭто может занять длительное время. По истечению этого времени Вам будет отправлен видеофайл.')
          name_f_path = src_name.partition('/')[-1]
          name_f_path_name = name_f_path.partition('.')[0]
          if param == 1:
              eng.detect_video_func_py('received/' + name_f_path, name_f_path_name,MinBlobArea,MaxBlobArea,imop_streal,imcl_streal, nargout=0)
          elif param == 0:
              eng.detect_video_func_py('received/' + name_f_path, name_f_path_name, nargout=0)
          file_to_send = open(name_f_path_name + '_detect.mp4', 'rb')
          bot.send_document(message.chat.id, file_to_send)
          file_to_send.close()
          bot.send_message(message.from_user.id, text='Видео обработанно! Чтобы обработать еще одно видео введите /go!')

      def detect_stabl(message):
          global param
          bot.reply_to(message, text='Началось детектирование объектов с предварительной стабилизацией на '
                                     'вашей видеопоследовательности.\nЭто может занять длительное время. По истечению этого времени Вам будет отправлен видеофайл.')
          name_f_path = src_name.partition('/')[-1]
          name_f_path_name = name_f_path.partition('.')[0]
          if param == 1:
              eng.stabilization_detect_video_func_py('received/' + name_f_path, name_f_path_name,MinBlobArea,MaxBlobArea,imop_streal,imcl_streal, nargout=0)
          elif param == 0:
              eng.stabilization_detect_video_func_py('received/' + name_f_path, name_f_path_name, nargout=0)
          file_to_send = open(name_f_path_name + '_detect_stabl.mp4', 'rb')
          bot.send_document(message.chat.id, file_to_send)
          file_to_send.close()
          bot.send_message(message.from_user.id, text='Видео обработанно! Чтобы обработать еще одно видео введите /go!')

      def stabl(message):
          global param
          bot.reply_to(message, text='Началась стабилизация '
                                     'вашей видеопоследовательности.\nЭто может занять длительное время. По истечению этого времени Вам будет отправлен видеофайл.')
          name_f_path = src_name.partition('/')[-1]
          name_f_path_name = name_f_path.partition('.')[0]
          eng.stabilization_video_func_py('received/' + name_f_path, name_f_path_name, nargout=0)
          file_to_send = open(name_f_path_name + '_stabl.mp4', 'rb')
          bot.send_document(message.chat.id, file_to_send)
          file_to_send.close()
          bot.send_message(message.from_user.id, text='Видео обработанно! Чтобы обработать еще одно видео введите /go!')

      @bot.message_handler(content_types=['document', 'video'])
      def handle_docs_photo(message):
          try:
              chat_id = message.chat.id
              # file_info = bot.get_file(message.document.file_id)
              file_info = bot.get_file(message.video.file_id)
              file_format = Path(file_info.file_path).suffixes

              if file_format == '.MP4' or '.MOV' or '.AVI':
                  bot.reply_to(message, "Формат верный, сохраняю! Это может занять некоторое время.")
                  downloaded_file = bot.download_file(file_info.file_path)
                  global src_name
                  src_name = file_info.file_path
                  global src
                  name_f_path = src_name.partition('/')[-1]
                  name_f_path_name = name_f_path.partition('.')[0]
                  src = 'D:/pythonProject6/received/' + str(name_f_path_name) + str(file_format[0])

                  with open(src, 'wb') as new_file:
                      new_file.write(downloaded_file)
                  bot.reply_to(message, "Видеофайл сохранен для дальнейшей обработки!")
                  global flag_file_save
                  flag_file_save = 1

                  keyboard = types.ReplyKeyboardMarkup(resize_keyboard=True)  # наша клавиатура
                  item1 = types.KeyboardButton("Детектирование")
                  item2 = types.KeyboardButton("Детектирование со стабилизацией")
                  item3 = types.KeyboardButton("Стабилизация")
                  keyboard.add(item1)
                  keyboard.add(item2)
                  keyboard.add(item3)
                  bot.send_message(message.from_user.id, text='Какое действие Вы хотите выполнить?',
                                   reply_markup=keyboard)


          except Exception as e:
              bot.reply_to(message, text='Отправьте мне видеофайл. Видеофайл должен быть в формате MP4, MOV или AVI.',
                           reply_markup=0)


      bot.polling(none_stop=True, interval=0)
  except Exception:
    pass

