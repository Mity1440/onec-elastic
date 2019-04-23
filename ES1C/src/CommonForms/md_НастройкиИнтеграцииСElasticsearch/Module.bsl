#Область ОбработчикиСобытийФормы

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	
	ПрочитатьНастройкиВФорму();
	
КонецПроцедуры

#КонецОбласти

#Область ОбработчикиКоманд

&НаКлиенте
Процедура ЗаписатьНастройки(Команда)
	
	ЗаписатьНастройкиНаСервере();
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

&НаСервере
Процедура ПрочитатьНастройкиВФорму()
	
	СписокНастроек = "ИспользоватьВерсионированиеElasticsearch, ИспользоватьВерсионированиеElasticsearch_СтароеЗначение";
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	md_ИспользоватьВерсионированиеElasticsearch.Значение КАК ИспользоватьВерсионированиеElasticsearch,
	|	md_ИспользоватьВерсионированиеElasticsearch.Значение КАК ИспользоватьВерсионированиеElasticsearch_СтароеЗначение
	|ИЗ
	|	Константа.md_ИспользоватьВерсионированиеElasticsearch КАК md_ИспользоватьВерсионированиеElasticsearch";
	
	Выборка = Запрос.Выполнить().Выбрать();
	Выборка.Следующий();
	
	ЗаполнитьЗначенияСвойств(ЭтотОбъект, Выборка, СписокНастроек);
	
Конецпроцедуры

&НаСервере
Процедура ЗаписатьНастройкиНаСервере()
	
	НачатьТранзакцию();

	Попытка

		Если НЕ ИспользоватьВерсионированиеElasticsearch = ИспользоватьВерсионированиеElasticsearch_СтароеЗначение Тогда

			Константы.md_ИспользоватьВерсионированиеElasticsearch.Установить(ИспользоватьВерсионированиеElasticsearch);

		КонецЕсли;

		ЗафиксироватьТранзакцию();

	Исключение

		ОтменитьТранзакцию();

		СтрокаИнформирования = ОписаниеОшибки();
		ВызватьИсключение СтрокаИнформирования;

	КонецПопытки;	
		
КонецПроцедуры

#КонецОбласти

