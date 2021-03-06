////////////////////////////////////////////////////////////////////////////////
// Интеграция elasticsearch (служебный)
//  
////////////////////////////////////////////////////////////////////////////////

#Область ПрограммныйИнтерфейс

Функция ПолучитьПредставлениеСсылкиДляES(СсылкаНаОбъект) Экспорт
    
    Возврат ПолучитьПредставлениеСтрокиUUIDДляES(Строка(СсылкаНаОбъект.УникальныйИдентификатор()));    
    
КонецФункции

#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

Функция ПолучитьСводныеДанныеОбъекта(СерверES, ИндексES, СсылкаНаОбъект) Экспорт
    
    КодСостоянияОшибкаИнтернетСоединения = 700;
    СводныеДанныеОбъекта = Новый Структура;
    
    Если НЕ (ЗначениеЗаполнено(СерверES) И ЗначениеЗаполнено(ИндексES) 
        И ЗначениеЗаполнено(СсылкаНаОбъект)) Тогда
        
        Возврат СводныеДанныеОбъекта;
    	
    КонецЕсли; 
    
    ШаблонАдресаРесурса = 
    "%1/_doc/_search?q=Object_ID:%2&_source=Object_ID,Object_DateTime,Object_User,Object_Version,Object_User_1С";
    
    АдресРесурса = md_СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(ШаблонАдресаРесурса,
    ИндексES, 
    md_ВерсионированиеElasticsearchСлужебный.ПолучитьПредставлениеСсылкиДляES(СсылкаНаОбъект));
   
    ЗаголовкиЗапроса = Новый Соответствие;
	ЗаголовкиЗапроса.Вставить("Content-Type", "application/json");
    
    ПараметрыОтправкиПакета  = md_ОбщегоНазначения.ЗначенияРеквизитовОбъекта(СерверES, "АдресСервера, Порт");
	СтруктураОтправкиПакета = Новый Структура("АдресСервера, Порт");
	ЗаполнитьЗначенияСвойств(СтруктураОтправкиПакета, ПараметрыОтправкиПакета);
	
	СтруктураОтправкиПакета.Вставить("Заголовки", ЗаголовкиЗапроса);
	СтруктураОтправкиПакета.Вставить("АдресРесурса", АдресРесурса);
	СтруктураОтправкиПакета.Вставить("HTTPМетод", "GET");
	СтруктураОтправкиПакета.Вставить("ВидОперации", "Сводные данные по объекту");
	СтруктураОтправкиПакета.Вставить("УникальныйИдентификатор", Новый УникальныйИдентификатор);
	  
    ОтветES = md_ВерсионированиеElasticsearchВызовСервера.ВыполнитьЗапросКElasticSearch(СтруктураОтправкиПакета);
    
    СводныеДанныеПоОтветуES(ОтветES, СводныеДанныеОбъекта);
    
    Если НЕ СводныеДанныеОбъекта.Количество() = 0 Тогда
                
        СводныеДанныеОбъекта.Вставить("Сервер", Строка(СерверES));
        СводныеДанныеОбъекта.Вставить("Индекс", ИндексES);
        СводныеДанныеОбъекта.Вставить("UUID",
        md_ВерсионированиеElasticsearchСлужебный.ПолучитьПредставлениеСсылкиДляES(СсылкаНаОбъект));
        
    ИначеЕсли ОтветES.КодСостояния = КодСостоянияОшибкаИнтернетСоединения Тогда 
        
        СводныеДанныеОбъекта.Вставить("ЕстьОшибка", Истина);
        СводныеДанныеОбъекта.Вставить("ТелоОтвета", Неопределено);
        ЗаполнитьЗначенияСвойств(СводныеДанныеОбъекта, ОтветES);
        
    КонецЕсли; 
    
    Возврат СводныеДанныеОбъекта;
    
КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Функция ПолучитьПредставлениеСтрокиUUIDДляES(СтрокаUUID) Экспорт
    
    Возврат СтрЗаменить(СтрокаUUID, "-", "");    
		
КонецФункции

Процедура ЗафиксироватьСобытиеИнтеграцииСElasticsearch(Уровень, Данные = Неопределено, Сообщение = "") Экспорт
    
    МетаданныеЗадания = Метаданные.РегламентныеЗадания.md_ОтправкаДанныхОчередейВElasticsearch;
	ЗаписьЖурналаРегистрации("ОбменДанными.Elasticsearch", Уровень, МетаданныеЗадания, Данные, Сообщение);
	
КонецПроцедуры

Функция СводныеДанныеПоОтветуES(ОтветES, СводныеДанные)
    
    НижнийПределКодСостоянияУспешно = 200;
    ВерхнийПределКодСостоянияУспешно = 300;
    Если НЕ (ОтветES.КодСостояния >= НижнийПределКодСостоянияУспешно 
        И ОтветES.КодСостояния < ВерхнийПределКодСостоянияУспешно) Тогда
        
        Возврат СводныеДанные;
        
    КонецЕсли; 
        
    ЧтениеJSON = Новый ЧтениеJSON;
    ЧтениеJSON.УстановитьСтроку(ОтветES.ТелоОтвета);
    
    ДокументJSON = ПрочитатьJSON(ЧтениеJSON, Истина);
    
    ДанныеПоиска = ДокументJSON["hits"];
    Если НЕ ДанныеПоиска = Неопределено Тогда
        
        СводныеДанные.Вставить("ВсегоВерсий", ДанныеПоиска["total"]);
        СводныеДанные.Вставить("КраткиеХарактеристикиВерсий", Новый Массив);
        
        КраткиеВерсии = ДанныеПоиска["hits"];
        
        Для каждого КраткаяВерсия Из КраткиеВерсии Цикл
            
            СтруктураКраткойВерсии = Новый Структура("Object_DateTime, Object_User, Object_Version, Object_User_1C");
            ДанныеПолей = КраткаяВерсия["_source"];
            
            // а вот здесь происходит магия, метод ЗаполнитьЗначенияСвойств - не отрабатывает.
            СтруктураКраткойВерсии.Object_DateTime = ДанныеПолей["Object_DateTime"];
            СтруктураКраткойВерсии.Object_User = ДанныеПолей["Object_User"]; 
            СтруктураКраткойВерсии.Object_Version = ДанныеПолей["Object_Version"];
            СтруктураКраткойВерсии.Object_User_1C = ДанныеПолей["Object_User_1C"];
            
            СводныеДанные.КраткиеХарактеристикиВерсий.Добавить(СтруктураКраткойВерсии);
            
        КонецЦикла; 

    КонецЕсли; 
    
    Возврат СводныеДанные;
    
КонецФункции


#Область ФормированиеВерсийОбъектов

Процедура ЗаписатьОписаниеВДокумент(ЗаписьJSON, ОписаниеПоляОбъекта) Экспорт
	
	ЗаписьJSON.ЗаписатьИмяСвойства(ОписаниеПоляОбъекта.Ключ);
    
    Если ТипЗнч(ОписаниеПоляОбъекта.Значение) = Тип("Дата") Тогда
        
		ЗаписьJSON.ЗаписатьЗначение(
        ЗаписатьДатуJSON(ОписаниеПоляОбъекта.Значение, ФорматДатыJSON.ISO, ВариантЗаписиДатыJSON.УниверсальнаяДата));	
        
    Иначе
        
		ЗаписьJSON.ЗаписатьЗначение(ОписаниеПоляОбъекта.Значение);
        
	КонецЕсли; 
	
КонецПроцедуры

Процедура ЗаписатьСтрокуТабличнойЧастиВПоток(ЗаписьJSON, СтрокаТабЧасти, Реквизиты);
        
    ЗаписатьМассивРевизитов(ЗаписьJSON, Реквизиты, СтрокаТабЧасти);
    
КонецПроцедуры 

Процедура ЗаписатьТабличнуюЧастьВПоток(ЗаписьJSON, ТабличнаяЧасть, Объект)
    
    ЗаписьJSON.ЗаписатьИмяСвойства(ТабличнаяЧасть.Имя);
    ЗаписьJSON.ЗаписатьНачалоМассива();
    
    СтандарныеРквизиты = ТабличнаяЧасть.СтандартныеРеквизиты;
    Реквизиты = ТабличнаяЧасть.Реквизиты;
    
    Для Каждого СтрокаТабЧасти Из Объект[ТабличнаяЧасть.Имя] Цикл
        
        ЗаписьJSON.ЗаписатьНачалоОбъекта();
        
        ЗаписатьСтрокуТабличнойЧастиВПоток(ЗаписьJSON, СтрокаТабЧасти, СтандарныеРквизиты);
        ЗаписатьСтрокуТабличнойЧастиВПоток(ЗаписьJSON, СтрокаТабЧасти, Реквизиты);
        
        ЗаписьJSON.ЗаписатьКонецОбъекта();
        
    КонецЦикла; 
    
    ЗаписьJSON.ЗаписатьКонецМассива();
    
КонецПроцедуры 

Процедура ЗаписатьТабличныеЧастиДокумента(ЗаписьJSON, ТабличныеЧасти, Объект)
    
    Для Каждого ТабличнаяЧасть Из ТабличныеЧасти Цикл
        
        ЗаписатьТабличнуюЧастьВПоток(ЗаписьJSON, ТабличнаяЧасть, Объект);
                
    КонецЦикла; 
    
КонецПроцедуры 

Процедура ЗаписатьЗначениеДокумента(ЗаписьJSON, Объект)
    
    МетаданныеОбъекта = Объект.Метаданные(); 

    ЗаписьJSON.ЗаписатьИмяСвойства("#value");
    ЗаписьJSON.ЗаписатьНачалоОбъекта();
    
    ЗаписатьРеквизитыДокумента(ЗаписьJSON, МетаданныеОбъекта.СтандартныеРеквизиты, Объект);
    ЗаписатьРеквизитыДокумента(ЗаписьJSON, МетаданныеОбъекта.Реквизиты, Объект);
    
    ЗаписатьТабличныеЧастиДокумента(ЗаписьJSON, МетаданныеОбъекта.ТабличныеЧасти, Объект);
    
    ЗаписьJSON.ЗаписатьКонецОбъекта();
        
КонецПроцедуры 

Процедура ЗаписатьПустоеСвойство(ЗаписьJSON, ИмяСвойтсва)
    
    ЗаписьJSON.ЗаписатьИмяСвойства(ИмяСвойтсва);   
    ЗаписьJSON.ЗаписатьЗначение(Неопределено);
    
КонецПроцедуры 

Процедура ЗаписатьСвойствоВПотокДокумента(ЗаписьJSON, ИмяСвойства, ЗначениеСвойства)
    
    ЗаписьJSON.ЗаписатьИмяСвойства(ИмяСвойства);
    СериализаторXDTO.ЗаписатьJSON(ЗаписьJSON, ЗначениеСвойства, НазначениеТипаXML.Явное);
    
КонецПроцедуры 

Процедура ЗаписатьМассивРевизитов(ЗаписьJSON, МассивРеквизитов, Объект);
    
    МассивЗапрещенныхТипов = Новый Массив;
    МассивЗапрещенныхТипов.Добавить(Новый ОписаниеТипов("ХранилищеЗначения"));
    
    Для Каждого Реквизит Из МассивРеквизитов Цикл
        
        Если НЕ МассивЗапрещенныхТипов.Найти(Реквизит.Тип) = Неопределено Тогда
            
            ЗаписатьПустоеСвойство(ЗаписьJSON, Реквизит.Имя);
            Продолжить;
            
        КонецЕсли;
        
        ЗаписатьСвойствоВПотокДокумента(ЗаписьJSON, Реквизит.Имя, Объект[Реквизит.Имя]);
        
    КонецЦикла;
    
КонецПроцедуры 

Процедура ЗаписатьРеквизитыДокумента(ЗаписьJSON, РеквизитыОбъекта, Объект)
    
    ЗаписатьМассивРевизитов(ЗаписьJSON, РеквизитыОбъекта, Объект);
           
КонецПроцедуры 

Процедура СформироватьПредставлениеВерсииДокумента(ЗаписьJSON, Объект);
    
    МетаданныеОбъекта = Объект.Метаданные(); 
       
    ЗаписьJSON.ЗаписатьНачалоОбъекта();
    
    ЗаписатьТипДокумента(ЗаписьJSON, МетаданныеОбъекта.Имя);
    
    ЗаписатьЗначениеДокумента(ЗаписьJSON, Объект);
            
    ЗаписьJSON.ЗаписатьКонецОбъекта();
           
КонецПроцедуры 

Процедура ЗаписатьТипДокумента(ЗаписьJSON, Имя)
    
    ЗаписьJSON.ЗаписатьИмяСвойства("#type");
    ЗаписьJSON.ЗаписатьЗначение(СтрЗаменить("jcfg:DocumentObject.%1", "%1", Имя)); 
    
КонецПроцедуры

Процедура ЗаписатьЗаголовокСообщения(ЗаписьJSON, СтруктураОбъекта)
    
    Для каждого ОписаниеПоляОбъекта Из СтруктураОбъекта Цикл
        
        ЗаписатьОписаниеВДокумент(ЗаписьJSON, ОписаниеПоляОбъекта);	
        
    КонецЦикла; 
    
    ЗаписьJSON.ЗаписатьИмяСвойства("DataFields");

КонецПроцедуры
 
Функция ПредставлениеОбъектавJSONПоРеквизитно(Объект, СтруктураОбъекта)
    
    ЗаписьJSON = Новый ЗаписьJSON;
    ЗаписьJSON.ПроверятьСтруктуру = Истина;
    
    ПараметрыЗаписиJSON = Новый ПараметрыЗаписиJSON;
    ЗаписьJSON.УстановитьСтроку(ПараметрыЗаписиJSON);
    
    ЗаписьJSON.ЗаписатьНачалоОбъекта();    
    ЗаписатьЗаголовокСообщения(ЗаписьJSON, СтруктураОбъекта);
       
    СформироватьПредставлениеВерсииДокумента(ЗаписьJSON, Объект);

    ЗаписьJSON.ЗаписатьКонецОбъекта();
    
    МаксимальнаяСтепеньСжатия = 9;
    МаксимальноеСжатие = Новый СжатиеДанных(МаксимальнаяСтепеньСжатия);
    
    СообщениеОтправки = Новый ХранилищеЗначения(ЗаписьJSON.Закрыть(), МаксимальноеСжатие);

    Возврат СообщениеОтправки;
    
КонецФункции

Функция ПредставлениеОбъектавJSONСтандартнойСериализацией(Объект, СтруктураОбъекта)
    
    ЗаписьJSON = Новый ЗаписьJSON;
    ЗаписьJSON.ПроверятьСтруктуру = Истина;
    
    ПараметрыЗаписиJSON = Новый ПараметрыЗаписиJSON;
    ЗаписьJSON.УстановитьСтроку(ПараметрыЗаписиJSON);
    
    ЗаписьJSON.ЗаписатьНачалоОбъекта();    
    ЗаписатьЗаголовокСообщения(ЗаписьJSON, СтруктураОбъекта);
    
    СериализаторXDTO.ЗаписатьJSON(ЗаписьJSON, Объект, НазначениеТипаXML.Явное);
    
    ЗаписьJSON.ЗаписатьКонецОбъекта();
    
    МаксимальноеСжатие = Новый СжатиеДанных(9);
    
    СообщениеОтправки = Новый ХранилищеЗначения(ЗаписьJSON.Закрыть(), МаксимальноеСжатие);
    
    Возврат СообщениеОтправки;
    
КонецФункции

// Возвращает сериализованное значение объекта в соответствии со способом сериализации с Elasticsearch.
// 
// Параметры:
//  Объект - ДокументОбъект - Объект документа сериализации
//  СтруктураОбъекта - Струкутра - Структура с данными к сериализации
//  ПараметрыВерсионирования - Структура - структура с настройками версионирования 
//   
// Возвращаемое значение:
//  Булево - Истина, если интеграция используется.
//
Функция СообщенияОтправкиПоПараметрам(Объект, СтруктураОбъекта, ПараметрыВерсионирования) Экспорт
     
    СообщенияОтправки = Новый Соответствие;
    
    Для Каждого ПараметрВерсионирования Из ПараметрыВерсионирования Цикл
        
        СпособСериализации = ПараметрВерсионирования.СпособСериализации;
        МенеджерСпособов = Перечисления.md_СпособыСериализацииДокументовElasticsearch;
        
        Если ЗначениеЗаполнено(СпособСериализации) Тогда
            
            СообщениеОтправки = Неопределено;
            
            Если СпособСериализации = МенеджерСпособов.СериализацияJSONПоРеквизитно Тогда
                
                СообщениеОтправки = ПредставлениеОбъектавJSONПоРеквизитно(Объект, СтруктураОбъекта);
                
            ИначеЕсли СпособСериализации = МенеджерСпособов.СтандартнаяСериализацияJSON Тогда
                
                СообщениеОтправки = ПредставлениеОбъектавJSONСтандартнойСериализацией(Объект, СтруктураОбъекта);
                
            КонецЕсли; 
            
            Если ЗначениеЗаполнено(СообщениеОтправки) Тогда
                
                СообщенияОтправки.Вставить(СпособСериализации, СообщениеОтправки);    
                
            КонецЕсли; 
                        
        КонецЕсли;
        
    КонецЦикла;
    
    Возврат СообщенияОтправки;
        
КонецФункции

#КонецОбласти 

#КонецОбласти 

