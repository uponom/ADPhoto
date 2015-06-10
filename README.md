# ADPhoto
ADPhoto v0.3

Powershell module for uploading jpg-files as thumbnailPhoto attribute into Active Directory objects (user or contact)

The module contains functions to upload the photos of users/contacts from the JPG files to Active Directory into thumbnailPhoto object's attribute.
Supplied as a script ADPhotos.ps1
Can be used as a script just for upload photos or it can automatically installs itself as a Powershell module (see Command line parameters).
For install the module manually: change the file extension to .psm1 and copy it to the folder specified in environment variable PSModulePath

The general principle of working:
Photos will be taken from files which set by Path parameter, then resolution will be reduced to the value specified in ResizeTo parameter, after that file names will be compared with AD objects for the attribute specified in the ADAttr parameter and, finally, photos will be recorded in the attribute thumbnailPhoto

Prerequisites:
It is necessary to prepare the photo files - the file name must match the value passed in the parameter ADAttr. File Type: JPG

[RU]
Модуль содержит функции для загрузки фотографий пользователей/контактов из файлов формата JPG в Active Directory в атрибут thumbnailPhoto
Поставляется в виде скрипта ADPhotos.ps1
Может использоваться как скрипт для загрузки фотографий либо автоматически устанавливать себя как модуль Powershell (см. параметры командной строки). 
Для установки модуля вручную: смените pасширение файла на .psm1 и скопируйте его в папку, указанную в переменной среды окружения PSModulePath

Общий принцип работы функций модуля:
Фотографии пользователей будут взяты из пути, указанного в параметре Path, разрешение будет уменьшено до значения, указанного в параметре ResizeTo, имена файлов будут сопоставлены с объектами в AD по атрибуту, указанному в параметре ADAttr и, в итоге, фото будут записаны в атрибут thumbnailPhoto

Предварительные требования:
Необходимо подготовить файлы с фотографиями - имя файла должно совпадать со значением, передаваемым в параметре ADAttr. Тип файлов: JPG
