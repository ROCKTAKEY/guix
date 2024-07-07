;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017, 2019, 2020 Hartmut Goebel <h.goebel@crazy-compilers.com>
;;; Copyright © 2020 Marius Bakke <marius@gnu.org>
;;; Copyright © 2021, 2022 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2022 Brendan Tildesley <mail@brendan.scot>
;;; Copyright © 2022 Petr Hodina <phodina@protonmail.com>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages kde-pim)
  #:use-module (guix build-system qt)
  #:use-module (guix gexp)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages aidc)
  #:use-module (gnu packages base)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cyrus-sasl)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages kde)
  #:use-module (gnu packages kde-frameworks)
  #:use-module (gnu packages openldap)
  #:use-module (gnu packages pdf)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages search)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages xml))

(define-public akonadi
  (package
    (name "akonadi")
    (version "24.05.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://kde/stable/release-service/"
                                  version "/src/akonadi-" version ".tar.xz"))
              (sha256
               (base32
                "0ygxj2hhslg5frarwhmdqqhvd37kzcgm60krs979f378dkj6cyc8"))
              (patches (search-patches "akonadi-paths.patch"
                                       "akonadi-timestamps.patch"
                                       "akonadi-not-relocatable.patch"))))
    (build-system qt-build-system)
    (native-inputs
     (list dbus
           extra-cmake-modules
           qttools
           shared-mime-info
           pkg-config))
    (inputs
     (list boost
           libaccounts-qt6
           kconfig
           kconfigwidgets
           kcoreaddons
           kcrash
           ki18n
           kiconthemes
           kio
           kitemmodels
           kitemviews
           kwidgetsaddons
           kwindowsystem
           kxmlgui
           libxml2
           libxslt
           ;; Do NOT add mysql or postgresql to the inputs. Otherwise the binaries
           ;; and wrapped files will refer to them, even if the user choices none
           ;; of these.  Executables are searched on $PATH then.
           signond))
    (propagated-inputs (list sqlite kaccounts-integration))
    (arguments
     (list #:qtbase qtbase
           #:tests? #f
           #:configure-flags #~'("-DDATABASE_BACKEND=SQLITE") ;lightweight
           #:modules `((ice-9 textual-ports)
                       ,@%qt-build-system-modules)
           #:phases
           #~(modify-phases (@ (guix build qt-build-system) %standard-phases)
               (replace 'check
                 (lambda* (#:key tests? #:allow-other-keys)
                   (when tests?
                     (setenv "PATH"
                             (string-append (getcwd) "/bin" ":"
                                            (getenv "PATH")))
                     (invoke "dbus-launch" "ctest" "-E"
                             "(AkonadiServer-dbconfigtest|mimetypecheckertest|entitytreemodeltest|akonadi-sqlite-testenvironmenttest|akonadi-sqlite-autoincrementtest|akonadi-sqlite-attributefactorytest|akonadi-sqlite-collectionpathresolvertest|akonadi-sqlite-collectionattributetest|akonadi-sqlite-itemfetchtest|akonadi-sqlite-itemappendtest|akonadi-sqlite-itemstoretest|akonadi-sqlite-itemdeletetest|akonadi-sqlite-entitycachetest|akonadi-sqlite-monitortest|akonadi-sqlite-changerecordertest|akonadi-sqlite-resourcetest|akonadi-sqlite-subscriptiontest|akonadi-sqlite-transactiontest|akonadi-sqlite-itemcopytest|akonadi-sqlite-itemmovetest|akonadi-sqlite-invalidatecachejobtest|akonadi-sqlite-collectioncreatetest|akonadi-sqlite-collectioncopytest|akonadi-sqlite-collectionmovetest|akonadi-sqlite-collectionsynctest|akonadi-sqlite-itemsynctest)"))))
               (add-before 'configure 'add-definitions
                 (lambda* (#:key outputs inputs #:allow-other-keys)
                   (with-output-to-file "CMakeLists.txt.new"
                     (lambda _
                       (display (string-append
                                 "add_compile_definitions(\n"
                                 "NIX_OUT=\""
                                 #$output "\"\n" ")\n\n"))
                       (display (call-with-input-file "CMakeLists.txt"
                                  get-string-all))))
                   (rename-file "CMakeLists.txt.new" "CMakeLists.txt"))))))
    (home-page "https://kontact.kde.org/components/akonadi/")
    (synopsis "Extensible cross-desktop storage service for PIM")
    (description
     "Akonadi is an extensible cross-desktop Personal Information
Management (PIM) storage service.  It provides a common framework for
applications to store and access mail, calendars, addressbooks, and other PIM
data.

This package contains the Akonadi PIM storage server and associated
programs.")
    (license license:fdl1.2+)))

(define-public akonadi-calendar
  (package
    (name "akonadi-calendar")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/akonadi-calendar-" version ".tar.xz"))
       (sha256
        (base32 "0nwl3jn7qqhs19ydxidjzh7vdll5s17pw4xaazmd3g7fg6mngnzh"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules))
    (inputs
     (list akonadi-contacts
           akonadi-mime
           boost
           grantleetheme
           kcalutils
           kcodecs
           kcontacts
           kdbusaddons
           kiconthemes
           kio
           kitemmodels
           kmailtransport
           kmime
           kmessagelib
           knotifications
           kpimtextedit
           ksmtp
           ktextwidgets
           kxmlgui
           kwallet))
    (propagated-inputs (list akonadi
                             kcalendarcore
                             ki18n
                             kwidgetsaddons
                             kidentitymanagement))
    (arguments
     (list #:qtbase qtbase
           #:tests? #f))  ;; TODO: 1/1 test fails
    (home-page "https://api.kde.org/kdepim/akonadi/html/index.html")
    (synopsis "Library providing calendar helpers for Akonadi items")
    (description "This library manages calendar specific actions for
collection and item views.")
    (license license:lgpl2.0+)))

(define-public akonadi-contacts
  (package
    (name "akonadi-contacts")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/akonadi-contacts-" version ".tar.xz"))
       (sha256
        (base32 "1207dgilr5y4b3g3fk2ywyvb6mryq2xrpkhi6cyhgn8k84q201fn"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules))
    (inputs
     (list akonadi
           boost
           grantleetheme
           kauth
           kcmutils
           kcodecs
           kcompletion
           kconfigwidgets
           kcontacts
           kcoreaddons
           kdbusaddons
           ki18n
           kiconthemes
           kitemmodels
           kitemviews
           kjobwidgets
           kmime
           kservice
           ktextwidgets
           ktexttemplate
           ktextaddons
           ktexteditor
           kwidgetsaddons
           kxmlgui
           prison
           kio
           solid
           sonnet))
    (arguments
     (list #:qtbase qtbase))
    (home-page "https://api.kde.org/kdepim/akonadi/html/index.html")
    (synopsis "Akonadi contacts access library")
    (description "Akonadi Contacts is a library that effectively bridges the
type-agnostic API of the Akonadi client libraries and the domain-specific
KContacts library.  It provides jobs, models and other helpers to make working
with contacts and addressbooks through Akonadi easier.

The library provides a complex dialog for editing contacts and several models
to list and filter contacts.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public akonadi-mime
  (package
    (name "akonadi-mime")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/akonadi-mime-" version ".tar.xz"))
       (sha256
        (base32 "1y6h53jfy77g7198cp5rfv0zabvfjg6fsw95wp4khcjvmm0qhzqm"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules libxslt ;; xslt for generating interface descriptions
           shared-mime-info))
    (inputs
     (list akonadi
           boost
           kcodecs
           kconfig
           kconfigwidgets
           kdbusaddons
           ki18n
           kio
           kitemmodels
           kmime
           kwidgetsaddons
           kxmlgui))
    (home-page "https://api.kde.org/kdepim/akonadi/html/index.html")
    (arguments
     (list
      #:qtbase qtbase
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'copy-desktop-file-early
            (lambda _
              (let ((plugins-dir "/tmp/.local/share/akonadi/plugins/serializer"))
                (mkdir-p plugins-dir)
                (copy-file "serializers/akonadi_serializer_mail.desktop"
                           (string-append plugins-dir "/akonadi_serializer_mail.desktop")))))
          (add-before 'check 'check-setup
            (lambda _
              (setenv "HOME" "/tmp"))))))
    (synopsis "Akonadi MIME handling library")
    (description "Akonadi Mime is a library that effectively bridges the
type-agnostic API of the Akonadi client libraries and the domain-specific
KMime library.  It provides jobs, models and other helpers to make working
with emails through Akonadi easier.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public akonadi-notes
  (package
    (name "akonadi-notes")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/akonadi-notes-" version ".tar.xz"))
       (sha256
        (base32 "0cb1nbjlsx3lhz27ggrhmgrbgljhwrh7pssmx4jkljhahi57vwxa"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules))
    (inputs
     (list akonadi kcodecs ki18n kmime))
    (arguments (list #:qtbase qtbase))
    (home-page "https://api.kde.org/kdepim/akonadi/html/index.html")
    (synopsis "Akonadi notes access library")
    (description "Akonadi Notes is a library that effectively bridges the
type-agnostic API of the Akonadi client libraries and the domain-specific
KMime library.  It provides a helper class for note attachments and for
wrapping notes into KMime::Message objects.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public akonadi-search
  (package
    (name "akonadi-search")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/akonadi-search-" version ".tar.xz"))
       (sha256
        (base32 "11lasaim65d37n0q8pyxnn0sqqq2liz6va951qc3bav8njigsny1"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules
           ;; For tests.
           dbus))
    (inputs
     (list akonadi
           akonadi-mime
           boost
           kcalendarcore
           kcmutils
           kcontacts
           kcrash
           kdbusaddons
           ktextaddons
           ki18n
           kio
           kitemmodels
           kmime
           kxmlgui
           krunner
           kwindowsystem
           xapian))
    (arguments
     (list
      #:qtbase qtbase
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'disable-failing-test
            (lambda _
              ;; FIXME: This test fails because it fails to establish
              ;; a socket connection, seemingly due to failure during
              ;; DBus communication.  See also 'korganizer'.
              (substitute* "agent/autotests/CMakeLists.txt"
                ((".*schedulertest\\.cpp.*")
                 ""))))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "dbus-launch" "ctest" "-E"
                        "akonadi-sqlite-collectionindexingjobtest")))))))
    (home-page "https://api.kde.org/kdepim/akonadi/html/index.html")
    (synopsis "Akonadi search library")
    (description "This package provides a library used to search in the
Akonadi PIM data server.  It uses Xapian for indexing and querying.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public itinerary
  (package
    (name "itinerary")
    (version "23.04.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://kde/stable/release-service/"
                                  version "/src/" name "-" version ".tar.xz"))
              (sha256
               (base32
                "132x68wc4pallxgkvridfsimfq5m2g47fj9lcgz1kq4gdsidzf6i"))))
    (build-system qt-build-system)
    (arguments
     `(#:tests? #f)) ;Fails 20/27
    (native-inputs (list extra-cmake-modules))
    (inputs (list karchive
                  kdbusaddons
                  ki18n
                  kio
                  kirigami
                  kirigami-addons
                  kitinerary
                  kitemmodels
                  kcoreaddons
                  kcontacts
                  kholidays
                  kmime
                  knotifications
                  kpublictransport
                  kcalendarcore
                  khealthcertificate
                  kosmindoormap
                  kopeninghours
                  kpkpass
                  kunitconversion
                  kwindowsystem
                  prison
                  qtdeclarative-5
                  qtgraphicaleffects
                  qtlocation
                  qtmultimedia-5
                  qtquickcontrols2-5
                  qqc2-desktop-style
                  shared-mime-info
                  solid
                  sonnet
                  zlib))
    (home-page "https://invent.kde.org/pim/itinerary")
    (synopsis "Itinerary and boarding pass management")
    (description
     "This package provides a tool for managing itinerary and boarding pass
information.")
    (license ;GPL for programs, LGPL for libraries
             (list license:gpl2+ license:lgpl2.0+))))

(define-public kincidenceeditor
  (package
    (name "kincidenceeditor")
    (version "23.04.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/incidenceeditor-" version ".tar.xz"))
       (sha256
        (base32 "1pqfl7gqz7ibpns2gpwqpvzhsba7xj4ilhi4ax1vn3m086iyh3a0"))))
    (properties `((upstream-name . "incidenceeditor")))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules dbus))
    (inputs
     (list akonadi
           akonadi-calendar
           akonadi-contacts
           akonadi-mime
           boost
           grantlee
           grantleetheme
           kcalendarcore
           kcalendarsupport
           kcalutils
           kcodecs
           kcontacts
           kdbusaddons
           kdiagram
           keventviews
           ki18n
           kiconthemes
           kidentitymanagement
           kimap
           kio
           kitemmodels
           kldap
           kmailtransport
           kmime
           kpimcommon
           kpimtextedit
           ktextaddons
           ktextwidgets
           kwallet
           libkdepim
           qtbase-5))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (replace 'check
           (lambda* (#:key tests? #:allow-other-keys)
             (when tests?
               (invoke "dbus-launch" "ctest" ;; FIXME: tests fails.
                       "-E"
					   "(akonadi-sqlite-incidencedatetimetest|ktimezonecomboboxtest|testindividualmaildialog)")))))))
    (home-page "https://invent.kde.org/pim/incidenceeditor")
    (synopsis "KDE PIM library for editing incidences")
    (description "This library provides an incidence editor for KDE PIM.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public kaddressbook
  (package
    (name "kaddressbook")
    (version "23.04.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/kaddressbook-" version ".tar.xz"))
       (sha256
        (base32 "0zjbri91dh9vnwi6jqkbmyq667yzn8g4kw5v47qn8id2629zj6jq"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules kdoctools))
    (inputs
     (list akonadi
           akonadi-contacts
           akonadi-mime
           akonadi-search
           boost
           gpgme
           grantlee
           grantleetheme
           kcalendarcore
           kcmutils
           kcompletion
           kcontacts
           kcrash
           kdbusaddons
           ki18n
           kiconthemes
           kimap
           kio
           kitemmodels
           kmime
           kontactinterface
           kparts
           kpimcommon
           kpimtextedit
           ktextaddons
           ktextwidgets
           kxmlgui
           libkdepim
           libkleo
           breeze-icons ; default icon set, required for tests
           prison
           qgpgme
           qtbase-5))
    (home-page "https://kontact.kde.org/components/kaddressbook/")
    (synopsis "Address Book application to manage your contacts")
    (description "KAddressBook stores all the personal details of your family,
friends and other contacts.  It supports large variety of services, including
NextCloud, Kolab, Google Contacts, Microsoft Exchange (EWS) or any standard
CalDAV server.")
    (license (list license:gpl2+ license:lgpl2.0+ license:fdl1.2+))))

(define-public kblog
  (package
    (name "kblog")
    (version "20.04.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/kblog-" version ".tar.xz"))
       (sha256
        (base32 "1d5r9ivc1xmhkrz780xga87p84h7dnxjl981qap16gy37sxahcjr"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules))
    (inputs
     (list kcalendarcore
           kcoreaddons
           ki18n
           kio
           kxmlrpcclient
           qtbase-5
           syndication))
    ;; Note: Some tests take up to 90 sec.
    (home-page "https://invent.kde.org/pim/kblog")
    (synopsis "Client-side support library for web application remote blogging
APIs")
    (description "KBlog is a library for calling functions on Blogger 1.0,
MetaWeblog, MovableType and GData compatible blogs.  It calls the APIs using
KXmlRpcClient and Syndication.  It supports asynchronous sending and fetching
of posts and, if supported on the server, multimedia files.  Almost every
modern blogging web application that provides an XML data interface supports
one of the APIs mentioned above.")
    (license license:lgpl2.0+)))

(define-public kaccounts-integration
  (package
    (name "kaccounts-integration")
    (version "24.05.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://kde/stable/release-service/"
                                  version "/src/" name "-" version ".tar.xz"))
              (sha256
               (base32
                "0dbv1yv6qq0rgjlczmky7fmwa3rspyssd6grdbgzyy3k0v35m1fi"))))
    (build-system qt-build-system)
    (native-inputs (list extra-cmake-modules))
    (inputs (list kcmutils
                  ki18n
                  kcoreaddons
                  kdbusaddons
                  kdeclarative
                  kwallet
                  kio
                  libaccounts-qt6
                  qcoro-qt6
                  signond-qt6))
    (arguments (list #:qtbase qtbase))
    (home-page "https://invent.kde.org/network/kaccounts-integration")
    (synopsis "Online account management system")
    (description "The Kaccounts Integration library provides online account
management system and its Plasma integration components.")
    (license license:lgpl2.0+)))

(define-public kaccounts-providers
  (package
    (name "kaccounts-providers")
    (version "24.05.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://kde/stable/release-service/"
                                  version "/src/" name "-" version ".tar.xz"))
              (sha256
               (base32
                "1mfidlhy8jh3ar9rpn39a52q6sfhc5f4yn30p2ihv9l7xi5r9vk0"))))
    (build-system qt-build-system)
    (native-inputs (list extra-cmake-modules intltool))
    (inputs (list kaccounts-integration
                  kcoreaddons
                  kdeclarative
                  kpackage
                  ki18n
                  kio
                  libaccounts-qt6
                  qtwebengine
                  signond-qt6))
    (arguments (list #:qtbase qtbase))
    (home-page "https://invent.kde.org/network/kaccounts-providers")
    (synopsis "Online account providers for the KAccounts system")
    (description "This package provides online account providers for the
KAccounts system.")
    (license license:lgpl2.0+)))

(define-public kalendar
  (package
    (name "kalendar")
    (version "23.04.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://kde/stable/release-service/"
                                  version "/src/" name "-" version
                                  ".tar.xz"))
              (sha256
               (base32
                "1w56glv8m1rlk86v78h69d21ydxb6i61g1dk6mcizjr5rvi4liy0"))))
    (build-system qt-build-system)
    (arguments
     (list #:tests? #f ;All 2 tests fail
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'install 'wrap-script
                 (lambda* (#:key inputs outputs #:allow-other-keys)
                   (wrap-program (string-append #$output
                                                "/bin/kalendar")
                     `("PATH" ":" prefix
                       (,(string-append #$(this-package-input "akonadi")
                                        "/bin"))))))
               (delete 'check)
               (add-after 'wrap-script 'check-again
                 (lambda* (#:key tests? #:allow-other-keys)
                   (when tests?
                     (invoke "dbus-launch" "ctest")))))))
    (native-inputs (list dbus extra-cmake-modules))
    (inputs (list akonadi
                  akonadi-contacts
                  breeze-icons
                  gpgme
                  grantlee
                  grantleetheme
                  kio
                  kirigami
                  kirigami-addons
                  kdbusaddons
                  ki18n
                  kimap
                  kcalendarcore
                  kcalendarsupport
                  kconfigwidgets
                  kwindowsystem
                  kcoreaddons
                  kcontacts
                  kitemmodels
                  kmailcommon
                  kmessagelib
                  kmime
                  kidentitymanagement
                  kpimcommon
                  kpimtextedit
                  ktextaddons
                  ktextwidgets
                  akonadi-calendar
                  akonadi-mime
                  keventviews
                  kcalutils
                  kxmlgui
                  kiconthemes
                  libkdepim
                  libkleo
                  qtbase-5
                  qtdeclarative-5
                  qtquickcontrols2-5
                  qtsvg-5
                  qtquickcontrols-5
                  qtgraphicaleffects
                  qtlocation
                  qqc2-desktop-style
                  qtwebengine-5))
    (home-page "https://apps.kde.org/kalendar/")
    (synopsis "Calendar application")
    (description
     "Kalendar is a calendar application using Akonadi to sync with
external services.")
    (license license:gpl3+)))

(define-public kcalendarsupport
  (package
    (name "kcalendarsupport")
    (version "23.04.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/calendarsupport-" version ".tar.xz"))
       (sha256
        (base32 "1zk6kv5nhcd7a5llzh31890xpqdg522ahjdgbwsm7pcp62y0nbsj"))))
    (properties `((upstream-name . "calendarsupport")))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules qttools-5))
    (inputs
     (list akonadi
           akonadi-calendar
           akonadi-mime
           akonadi-notes
           boost
           kcalendarcore
           kcalutils
           kcompletion
           kdbusaddons
           kguiaddons
           kholidays
           ki18n
           kiconthemes
           kidentitymanagement
           kio
           kitemmodels
           kmime
           kpimcommon
           kpimtextedit
           ktextwidgets
           kxmlgui
           qtbase-5))
    (home-page "https://api.kde.org/kdepim/calendarsupport/html/index.html")
    (synopsis "Calendar Support library for KDE PIM")
    (description "The Calendar Support library provides helper utilities for
calendaring applications.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public kcalutils
  (package
    (name "kcalutils")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/kcalutils-" version ".tar.xz"))
       (sha256
        (base32 "1hiygvhw9nmqsz7pca6za9as06m8l0wsv78ski6gcjwzpi7qh0vq"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules libxml2)) ;; xmllint required for tests
    (inputs
     (list breeze-icons ; default icon set, required for tests
           kcalendarcore
           kcodecs
           kconfig
           kconfigwidgets
           kcoreaddons
           ki18n
           kiconthemes
           kidentitymanagement
           kpimtextedit
           ktextwidgets
           ktexttemplate
           kwidgetsaddons))
    (arguments
     (list #:qtbase qtbase
           #:tests? #f)) ;; TODO: seem to pull in some wrong theme
    (home-page "https://api.kde.org/kdepim/kcalutils/html/index.html")
    (synopsis "Library with utility functions for the handling of calendar
data")
    (description "This library provides a utility and user interface
functions for accessing calendar data using the kcalcore API.")
    (license  license:lgpl2.0+)))

(define-public kdepim-runtime
  (package
    (name "kdepim-runtime")
    (version "23.04.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/kdepim-runtime-" version ".tar.xz"))
       (sha256
        (base32 "1wvwibq6zzjlhh8yqrlqras0m8i01ynlwj9z6l3f0g0hyyz5nkw4"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules dbus kdoctools libxslt shared-mime-info))
    (inputs
     (list akonadi
           akonadi-calendar
           akonadi-contacts
           akonadi-mime
           akonadi-notes
           boost
           cyrus-sasl
           grantlee
           grantleetheme
           kcalendarcore
           kcalutils
           kcmutils
           kcodecs
           kconfig
           kconfigwidgets
           kcontacts
           kdav
           kholidays
           kidentitymanagement
           kimap
           kio
           kitemmodels
           kmailtransport
           kldap
           kmbox
           kmime
           knotifications
           knotifyconfig
           kpimcommon
           kpimtextedit
           kross
           ktextwidgets
           kwallet
           kwindowsystem
           libkdepim
           libkgapi
           ;; TODO: libkolab
           qca
           qtbase-5
           qtdeclarative-5
           qtkeychain
           qtnetworkauth-5
           qtspeech-5
           qtwebchannel-5
           qtwebengine-5
           qtxmlpatterns))
    (arguments
      ;; TODO: 5/45 tests fail for quite different reasons, even with
      ;; "offscreen" and dbus
     `(#:phases (modify-phases %standard-phases
                  (add-after 'set-paths 'extend-CPLUS_INCLUDE_PATH
                    (lambda* (#:key inputs #:allow-other-keys)
                      ;; FIXME: <Akonadi/KMime/SpecialMailCollections> is not
                      ;; found during one of the compilation steps without
                      ;; this hack.
                      (setenv "CPLUS_INCLUDE_PATH"
                              (string-append
                               (assoc-ref inputs "akonadi-mime") "/include/KF5:"
                               (or (getenv "CPLUS_INCLUDE_PATH") "")))))
                  (replace 'check
                    (lambda* (#:key tests? #:allow-other-keys)
                      (when tests?
                        ;; FIXME: Atleast some appear to require network.
                        (invoke "dbus-launch" "ctest" "-E" "\
(akonadi-sqlite-synctest|akonadi-sqlite-pop3test|storecompacttest\
|akonadi-sqlite-ewstest|ewsmoveitemrequest_ut|ewsdeleteitemrequest_ut\
|ewsgetitemrequest_ut|ewsunsubscriberequest_ut|ewssettings_ut\
|templatemethodstest|akonadi-sqlite-serverbusytest|ewsattachment_ut|\\
testmovecollectiontask)")))))))
    (home-page "https://invent.kde.org/pim/kdepim-runtime")
    (synopsis "Runtime components for Akonadi KDE")
    (description "This package contains Akonadi agents written using KDE
Development Platform libraries.  Any package that uses Akonadi should probably
pull this in as a dependency.  The kres-bridges is also parts of this
package.")
    (license ;; Files vary a lot regarding the license. GPL2+ and LGPL2.1+
     ;; have been used in those I checked. But the archive also includes
     ;; license texts for GPL3 and AGPL3.
     (list license:gpl2+ license:lgpl2.0+))))

(define-public keventviews
  (package
    (name "keventviews")
    (version "23.04.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/eventviews-" version ".tar.xz"))
       (sha256
        (base32 "1nh8a7jy0sjsyi41pxhxwjkq6fr4yy9rqgcjjbj01dnx1ykz3d7l"))))
    (properties `((upstream-name . "eventviews")))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules qttools-5))
    (inputs
     (list akonadi
           akonadi-calendar
           akonadi-contacts
           boost
           kcalendarcore
           kcalendarsupport
           kcalutils
           kcodecs
           kcompletion
           kconfigwidgets
           kcontacts
           kdbusaddons
           kdiagram
           kguiaddons
           kholidays
           ki18n
           kiconthemes
           kidentitymanagement
           kio
           kitemmodels
           kmime
           kpimtextedit
           kservice
           ktextwidgets
           kxmlgui
           libkdepim
           qtbase-5))
    (home-page "https://invent.kde.org/pim/eventviews")
    (synopsis "KDE PIM library for creating events")
    (description "This library provides an event creator for KDE PIM.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public kgpg
  (package
    (name "kgpg")
    (version "23.04.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/kgpg-" version ".tar.xz"))
       (sha256
        (base32 "1ihxw1s4sq7cp5pm6rddcmvqk0v5gfg4v38b6yg8hyjg655x63jz"))))
    (build-system qt-build-system)
    (arguments
     (list #:phases
           #~(modify-phases %standard-phases
               (replace 'check
                 (lambda* (#:key tests? #:allow-other-keys)
                   (when tests?
                     (setenv "HOME" (getcwd))
                     (invoke "ctest")))))
           ;; XXX: Tests could fail randomly with:
           ;;   gpg: can't connect to the agent: IPC connect call failed
           ;;   gpg process did not finish. Cannot generate a new key pair.
           #:tests? #f))
    (native-inputs
     (list extra-cmake-modules
           gnupg ;; TODO: Remove after gpgme uses fixed path
           kdoctools
           pkg-config))
    (inputs
     (list akonadi
           akonadi-contacts
           boost
           gpgme
           grantlee
           grantleetheme
           karchive
           kcodecs
           kcontacts
           kcoreaddons
           kcrash
           kdbusaddons
           ki18n
           kiconthemes
           kio
           kitemmodels
           kjobwidgets
           knotifications
           kservice
           ktextwidgets
           kwidgetsaddons
           kwindowsystem
           kxmlgui
           breeze-icons ;; default icon set
           qtbase-5))
    (home-page "https://apps.kde.org/kgpg/")
    (synopsis "Graphical front end for GNU Privacy Guard")
    (description "Kgpg manages cryptographic keys for the GNU Privacy Guard,
and can encrypt, decrypt, sign, and verify files.  It features a simple editor
for applying cryptography to short pieces of text, and can also quickly apply
cryptography to the contents of the clipboard.")
    (license license:gpl2+)))

(define-public khealthcertificate
  (package
    (name "khealthcertificate")
    (version "23.01.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://kde/stable/plasma-mobile/" version
                                  "/khealthcertificate-" version ".tar.xz"))
              (sha256
               (base32
                "193agd3jg029vcq1h5hdg3gw6zgqcmszl6ffcrid0ajbbiic4pbm"))))
    (build-system qt-build-system)
    (arguments
     (list #:phases
           #~(modify-phases %standard-phases
               (replace 'check
                 (lambda* (#:key inputs tests? #:allow-other-keys)
                   (when tests?
                     (setenv "TZDIR"
                             (search-input-directory inputs "share/zoneinfo"))
                     (invoke "ctest" "-E"
                             "(icaovdsparsertest|eudgcparsertest)")))))))
    (native-inputs (list extra-cmake-modules pkg-config tzdata-for-tests))
    (inputs (list karchive
                  kcodecs
                  ki18n
                  openssl
                  qtdeclarative-5
                  zlib))
    (home-page "https://api.kde.org/khealthcertificate/html/index.html")
    (synopsis "Digital vaccination and recovery certificate library")
    (description
     "This package provides a library for arsing of digital vaccination,
test and recovery certificates.")
    (license license:lgpl2.0)))

(define-public kidentitymanagement
  (package
    (name "kidentitymanagement")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/kidentitymanagement-" version ".tar.xz"))
       (sha256
        (base32 "026i17j6spl0937klzf9ch26cmj7rrp617yrdq7917cwp9i7ah04"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules))
    (inputs
     (list kcodecs
           kcompletion
           kconfig
           kcoreaddons
           kiconthemes
           kio
           kpimtextedit
           ktextwidgets
           ktextaddons
           kxmlgui
           kirigami-addons))
    (arguments
     (list #:qtbase qtbase
           #:phases
           #~(modify-phases %standard-phases
               (add-before 'check 'set-home
                 (lambda _
                   (setenv "HOME" "/tmp/dummy-home")))))) ;; FIXME: what is this?
    (home-page "https://kontact.kde.org/")
    (synopsis "Library for shared identities between mail applications")
    (description "This library provides an API for managing user identities.")
    (license ;; GPL for programs, LGPL for libraries, FDL for documentation
     (list license:gpl2+ license:lgpl2.0+ license:fdl1.2+))))

(define-public kimap
  (package
    (name "kimap")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/kimap-" version ".tar.xz"))
       (sha256
        (base32 "1q4nxd31sjml31qicgpinf81rd8id71wm3kgx0v9byv7d0kysyqn"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules))
    (inputs
     (list cyrus-sasl
           kcoreaddons
           kcodecs
           ki18n
           kio
           kmime))
    (arguments (list #:qtbase qtbase))
    (home-page "https://api.kde.org/kdepim/kimap/html/index.html")
    (synopsis "Library for handling IMAP")
    (description "This library provides a job-based API for interacting with
an IMAP4rev1 server.  It manages connections, encryption and parameter quoting
and encoding, but otherwise provides quite a low-level interface to the
protocol.  This library does not implement an IMAP client; it merely makes it
easier to do so.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public kitinerary
  (package
    (name "kitinerary")
    (version "24.05.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://kde/stable/release-service/"
                                  version "/src/kitinerary-" version ".tar.xz"))
              (sha256
               (base32
                "1c7dd85n1amyi9hdzfjlchcj156kfy64rw915bymcbvdy6y3m6ji"))))
    (build-system qt-build-system)
    (arguments
     (list #:qtbase qtbase
           #:phases #~(modify-phases %standard-phases
                        (replace 'check
                          (lambda* (#:key inputs tests? #:allow-other-keys)
                            (when tests?
                              (setenv "TZDIR"
                                      (search-input-directory inputs "share/zoneinfo"))
                              (invoke "dbus-launch" "ctest" "-E"
                                      "(jsonlddocumenttest|mergeutiltest|locationutiltest|knowledgedbtest|airportdbtest|extractorscriptenginetest|pkpassextractortest|postprocessortest|calendarhandlertest|extractortest)")))))))
    (native-inputs (list dbus extra-cmake-modules tzdata-for-tests))
    (inputs (list kpkpass
                  kcalendarcore
                  karchive
                  ki18n
                  kcoreaddons
                  kcontacts
                  kmime
                  knotifications
                  shared-mime-info
                  openssl
                  poppler
                  qtdeclarative
                  libxml2
                  zlib
                  zxing-cpp))
    (home-page "https://apps.kde.org/itinerary/")
    (synopsis
     "Data Model and Extraction System for Travel Reservation information")
    (description "This package provides a library containing itinerary data
model and itinerary extraction code.")
    (license license:lgpl2.0)))

(define-public kldap
  (package
    (name "kldap")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/kldap-" version ".tar.xz"))
       (sha256
        (base32 "1nhr18h7f4qm196jjg5aqyky7v7w8n7iy07kzdk638381sarcmyz"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules kdoctools))
    (inputs
     (list ki18n kio kwidgetsaddons qtkeychain-qt6))
    (propagated-inputs
     (list cyrus-sasl openldap))
    (arguments (list #:qtbase qtbase))
    (home-page "https://api.kde.org/kdepim/kldap/html/index.html")
    (synopsis "Library for accessing LDAP")
    (description "This is a library for accessing LDAP with a convenient Qt
style C++ API.  LDAP (Lightweight Directory Access Protocol) is an application
protocol for querying and modifying directory services running over TCP/IP.")
    (license license:lgpl2.0+)))

(define-public kleopatra
  (package
    (name "kleopatra")
    (version "23.04.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/kleopatra-" version ".tar.xz"))
       (sha256
        (base32 "0lcl20yihsa8dq0s24akp5z0290vh9nxjjjdwqk88nz8vmsr29i0"))))
    (build-system qt-build-system)
    (native-inputs
     (list dbus extra-cmake-modules gnupg ;; TODO: Remove after gpgme uses fixed path
           kdoctools))
    (inputs
     (list boost
           gpgme
           kcmutils
           kcodecs
           kconfig
           kconfigwidgets
           kcoreaddons
           kcrash
           kdbusaddons
           ki18n
           kiconthemes
           kitemmodels
           kmime
           knotifications
           ktextwidgets
           kwidgetsaddons
           kwindowsystem
           kxmlgui
           libassuan
           libkleo
           breeze-icons ;; default icon set
           qgpgme
           qtbase-5))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (replace 'check
           (lambda* (#:key tests? #:allow-other-keys)
             (when tests?
               (invoke "dbus-launch" "ctest")))))))
    (home-page "https://apps.kde.org/kleopatra/")
    (synopsis "Certificate Manager and Unified Crypto GUI")
    (description "Kleopatra is a certificate manager and a universal crypto
GUI.  It supports managing X.509 and OpenPGP certificates in the GpgSM keybox
and retrieving certificates from LDAP servers.")
    (license ;; GPL for programs, FDL for documentation
     (list license:gpl2+ license:fdl1.2+))))

(define-public kmail
  (package
    (name "kmail")
    (version "23.04.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/kmail-" version ".tar.xz"))
       (sha256
        (base32 "16gz0i7na1pkyly9jnvavyffkawxf5irr92rd50w68p01b82dhc6"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules dbus kdoctools))
    (inputs
     (list akonadi
           akonadi-contacts
           akonadi-mime
           akonadi-search
           boost
           gpgme
           grantlee
           grantleetheme
           kbookmarks
           kcalendarcore
           kcalutils
           kcmutils
           kcodecs
           kconfig
           kconfigwidgets
           kcontacts
           kcrash
           kdbusaddons
           kguiaddons
           ki18n
           kiconthemes
           kidentitymanagement
           kimap
           kio
           kitemmodels
           kitemviews
           kjobwidgets
           kldap
           kmailcommon
           kmailtransport
           kmessagelib
           kmime
           knotifications
           knotifyconfig
           kontactinterface
           kparts
           kpimcommon
           kpimtextedit
           kservice
           ksyntaxhighlighting
           ktextaddons
           ktextwidgets
           kuserfeedback
           ktnef
           kwallet
           kwidgetsaddons
           kwindowsystem
           kxmlgui
           libgravatar
           libkdepim
           libkleo
           libksieve
           breeze-icons ; default icon set, required for tests
           qgpgme
           qtbase-5
           qtdeclarative-5
           qtkeychain
           qtwebchannel-5
           qtwebengine-5
           sonnet))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (replace 'check
           (lambda* (#:key tests? #:allow-other-keys)
             (when tests?
               (invoke "dbus-launch" "ctest" "-E" ;; FIXME: Many failing tests.
                       "(akonadi-sqlite-kmcomposerwintest|\
akonadi-sqlite-tagselectdialogtest|\
akonadi-sqlite-kmcommandstest|\
sendlateragent-sendlaterutiltest|\
sendlateragent-sendlaterconfigtest|\
followupreminder-followupreminderconfigtest|\
akonadi-sqlite-unifiedmailboxmanagertest)")))))))
    (home-page "https://kontact.kde.org/components/kmail/")
    (synopsis "Full featured graphical email client")
    (description "KMail supports multiple accounts, mail filtering and email
encryption.  The program let you configure your workflow and it has good
integration into KDE (Plasma Desktop) but is also usable with other Desktop
Environments.

KMail is the email component of Kontact, the integrated personal information
manager from KDE.")
    (license ;; GPL for programs, LGPL for libraries, FDL for documentation
     (list license:gpl2+ license:lgpl2.0+ license:fdl1.2+))))

(define-public kmailcommon
  (package
    (name "kmailcommon")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/mailcommon-" version ".tar.xz"))
       (sha256
        (base32 "0s23g08q5nx11vdpwxkqgzcs9xb6nycwsndfl6vpcnlbx10zsbfr"))))
    (properties `((upstream-name . "mailcommon")))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules dbus gnupg qttools))
    (inputs
     (list akonadi-contacts
           boost
           gpgme
           grantleetheme
           karchive
           kcodecs
           kconfig
           kconfigwidgets
           kcontacts
           kdbusaddons
           kguiaddons
           ki18n
           kiconthemes
           kidentitymanagement
           kimap
           kio
           kitemmodels
           kitemviews
           kldap
           kmailimporter
           kmailtransport
           kmime
           kpimtextedit
           ksyntaxhighlighting
           ktextaddons
           ktextwidgets
           kwallet
           kwidgetsaddons
           kwindowsystem
           kxmlgui
           libkleo
           libxslt
           phonon
           qgpgme
           qtwebchannel
           qtwebengine))
    (propagated-inputs (list akonadi
                             akonadi-mime
                             kcompletion
                             kmessagelib
                             kpimcommon
                             libkdepim))
    (arguments
     (list
      #:qtbase qtbase
      #:tests? #f))  ;; TODO: 12/62 tests fail
    (home-page "https://invent.kde.org/pim/mailcommon")
    (synopsis "KDE email utility library")
    (description "The mail common library provides utility functions for
dealing with email.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public kmailimporter
  (package
    (name "kmailimporter")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/mailimporter-" version ".tar.xz"))
       (sha256
        (base32 "0hjwz70ys2bi6l8c2anzc7mhcapcqsximrxh813sp36hqwsix52g"))))
    (properties `((upstream-name . "mailimporter")))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules))
    (inputs
     (list akonadi
           akonadi-contacts
           akonadi-mime
           grantleetheme
           boost
           kcompletion
           kconfig
           kconfigwidgets
           kcontacts
           kcoreaddons
           kdbusaddons
           ki18n
           kimap
           kio
           kitemmodels
           kmime
           kpimcommon
           kpimtextedit
           ktextaddons
           ktextwidgets
           kxmlgui
           libkdepim))
    (propagated-inputs (list karchive))
    (arguments (list #:qtbase qtbase))
    (home-page "https://invent.kde.org/pim/mailimporter")
    (synopsis "KDE mail importer library")
    (description "This package provides libraries for importing mails other
e-mail client programs into KMail and KDE PIM.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public kmailtransport
  (package
    (name "kmailtransport")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/kmailtransport-" version ".tar.xz"))
       (sha256
        (base32 "0ck6mr1zapk0ac96ffnps7pw5pzvb3d5v8lyjvv8acy3435j684z"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules kdoctools))
    (inputs
     (list akonadi
           akonadi-mime
           boost
           cyrus-sasl
           kcalendarcore
           kcmutils
           kcontacts
           kdbusaddons
           kconfigwidgets
           ki18n
           kitemmodels
           kio
           kmime
           ksmtp
           ktextwidgets
           kwallet
           libkgapi
           qtkeychain-qt6))
    (arguments
     (list
      #:qtbase qtbase
      #:tests? #f)) ;; 1/2 tests fail, require network.
    (home-page "https://api.kde.org/kdepim/kmailtransport/html/index.html")
    (synopsis "Mail transport service library")
    (description "This library provides an API and support code for managing
mail transport.")
    (license license:lgpl2.0+)))

(define-public kmbox
  (package
    (name "kmbox")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/kmbox-" version ".tar.xz"))
       (sha256
        (base32 "0g2pg80n37miinfv69mz6hpvdhhbprdvgbkvzafspaj9bram9xrr"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules))
    (inputs
     (list kcodecs kmime))
    (arguments (list #:qtbase qtbase))
    (home-page "https://api.kde.org/kdepim/kmbox/html/index.html")
    (synopsis "Library for handling mbox mailboxes")
    (description "This is a library for handling mailboxes in mbox format,
using a Qt/KMime C++ API.")
    (license license:lgpl2.0+ )))

(define-public kmessagelib
  (package
    (name "kmessagelib")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/messagelib-" version ".tar.xz"))
       (sha256
        (base32 "1m7mah1zqfn9r3jw1lg303kg023lgl77r6if5g4ifv3lsih52pgl"))))
    (properties `((upstream-name . "messagelib")))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules gnupg libxml2))
    (inputs
     (list akonadi-contacts
           akonadi-notes
           akonadi-search
           boost
           gpgme-1.23
           grantleetheme
           karchive
           kcalendarcore
           kcodecs
           kcompletion
           kconfig
           kconfigwidgets
           kcontacts
           kdbusaddons
           kguiaddons
           ki18n
           kiconthemes
           kimap
           kio
           kitemmodels
           kitemviews
           kjobwidgets
           kldap
           kmailtransport
           kmbox
           knewstuff
           knotifications
           kservice
           ksyntaxhighlighting
           ktextwidgets
           ktexttemplate
           kwallet
           kwidgetsaddons
           kwindowsystem
           kxmlgui
           libgravatar
           qca-qt6
           qgpgme-qt6-1.23
           qtdeclarative
           qtwebchannel
           qtwebengine
           sonnet))
    (propagated-inputs
     (list akonadi
           akonadi-mime
           kidentitymanagement
           kmime
           kpimcommon
           kpimtextedit
           ktextaddons
           libkdepim
           libkleo))
    (arguments
     (list #:qtbase qtbase
           #:tests? #f     ;TODO many test fail for quite different reasons
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'add-miss-PrintSupport
                 (lambda _
                   (substitute* "webengineviewer/src/CMakeLists.txt"
                     (("KF6::ConfigCore")
                      "KF6::ConfigCore\n    Qt::PrintSupport")))))))
    (home-page "https://invent.kde.org/pim/messagelib")
    (synopsis "KDE PIM messaging libraries")
    (description "This package provides several libraries for messages,
e.g. a message list, a mime tree parse, a template parser and the
kwebengineviewer.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public kmime
  (package
    (name "kmime")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/kmime-" version ".tar.xz"))
       (sha256
        (base32 "19dnp955vii3vi1jaxgbsyabbb35iaqvhz9nnz392r3wz7f3hbyq"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules tzdata-for-tests))
    (inputs
     (list kcodecs ki18n))
    (arguments
     (list #:qtbase qtbase
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'fix-test-case
                 (lambda* (#:key inputs tests? #:allow-other-keys)
                   (when tests?
                     (setenv "TZDIR" (search-input-directory
                                      inputs "share/zoneinfo"))))))))
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/")
    (synopsis "Library for handling MIME data")
    (description "This library provides an API for handling MIME
data.  MIME (Multipurpose Internet Mail Extensions) is an Internet Standard
that extends the format of e-mail to support text in character sets other than
US-ASCII, non-text attachments, multi-part message bodies, and header
information in non-ASCII character sets.")
    (license license:lgpl2.0+)))

(define-public knotes
  (package
    (name "knotes")
    (version "23.04.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/knotes-" version ".tar.xz"))
       (sha256
        (base32 "0f2a9xy2w909y792hwwnmsqvxx91azn6f0j0xl2mlmav00a4w6za"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules kdoctools libxslt))
    (inputs
     (list akonadi
           akonadi-contacts
           akonadi-mime
           akonadi-notes
           akonadi-search
           boost
           grantlee
           grantleetheme
           kcalendarcore
           kcalutils
           kcmutils
           kcompletion
           kconfig
           kconfigwidgets
           kcontacts
           kcoreaddons
           kcrash
           kdnssd
           kglobalaccel
           kiconthemes
           kimap
           kitemmodels
           kitemviews
           kmime
           knewstuff
           knotifications
           knotifyconfig
           kontactinterface
           kparts
           kpimcommon
           kpimtextedit
           ktextaddons
           ktextwidgets
           kwidgetsaddons
           kwindowsystem
           kxmlgui
           kxmlgui
           libkdepim
           breeze-icons ; default icon set, required for tests
           qtbase-5
           qtx11extras))
    (home-page "https://apps.kde.org/knotes/")
    (synopsis "Note-taking utility")
    (description "KNotes lets you write the computer equivalent of sticky
notes.  The notes are saved automatically when you exit the program, and they
display when you open the program.

Features:
@itemize
@item Write notes in your choice of font and background color
@item Use drag and drop to email your notes
@item Can be dragged into Calendar to book a time-slot
@item Notes can be printed
@end itemize")
    (license (list license:gpl2+ license:lgpl2.0+))))

(define-public kontactinterface
  (package
    (name "kontactinterface")
    (version "23.04.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/kontactinterface-" version ".tar.xz"))
       (sha256
        (base32 "16fg24hz9vx912cffc94x5zx4jv3k72mbxgp5ck50lydypx6rfns"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules))
    (inputs
     (list kcoreaddons
           ki18n
           kiconthemes
           kparts
           kwindowsystem
           kxmlgui
           qtbase-5
           qtx11extras))
    (home-page "https://api.kde.org/kdepim/kontactinterface/html/index.html")
    (synopsis "Kontact interface library")
    (description "This library provides the glue necessary for
application \"Parts\" to be embedded as a Kontact component (or plugin).")
    (license license:lgpl2.0+)))

(define-public korganizer
  (package
    (name "korganizer")
    (version "23.04.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/korganizer-" version ".tar.xz"))
       (sha256
        (base32 "1vp1jsmna059vvfj7xaj9fhhhq0lz9k0pphczkfbwm3gy6nzcavz"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules dbus qttools-5 kdoctools tzdata-for-tests))
    (inputs
     (list akonadi
           akonadi-calendar
           akonadi-contacts
           akonadi-mime
           akonadi-notes
           akonadi-search
           boost
           grantlee
           grantleetheme
           kcalendarcore
           kcalendarsupport
           kcalutils
           kcmutils
           kcodecs
           kcompletion
           kconfig
           kconfigwidgets
           kcontacts
           kcoreaddons
           kcrash
           kdbusaddons
           keventviews
           kholidays
           kiconthemes
           kidentitymanagement
           kimap
           kincidenceeditor
           kitemmodels
           kitemviews
           kjobwidgets
           kldap
           kmailtransport
           kmime
           knewstuff
           knotifications
           kontactinterface
           kparts
           kpimcommon
           kpimtextedit
           kservice
           ktextaddons
           kwallet
           kwidgetsaddons
           kwindowsystem
           kxmlgui
           libkdepim
           breeze-icons ; default icon set, required for tests
           phonon
           qtbase-5))
    (arguments
     '(#:phases
       (modify-phases %standard-phases
         (replace 'check
           (lambda* (#:key inputs tests? #:allow-other-keys)
             (when tests?
               (setenv "TZDIR" (search-input-directory
                                inputs "share/zoneinfo"))
               (invoke "dbus-launch" "ctest")))))))
    (home-page "https://apps.kde.org/korganizer/")
    (synopsis "Organizational assistant, providing calendars and other similar
functionality")
    (description "KOrganizer is the calendar and scheduling component of
Kontact.  It provides management of events and tasks, alarm notification, web
export, network transparent handling of data, group scheduling, import and
export of calendar files and more.  It is able to work together with a wide
variety of calendaring services, including NextCloud, Kolab, Google Calendar
and others.  KOrganizer is fully customizable to your needs and is an integral
part of the Kontact suite, which aims to be a complete solution for organizing
your personal data.  KOrganizer supports the two dominant standards for storing
and exchanging calendar data, vCalendar and iCalendar.")
    (license ;; GPL for programs, LGPL for libraries, FDL for documentation
     (list license:gpl2+ license:lgpl2.0+ license:fdl1.2+))))

(define-public kpeoplevcard
  (package
    (name "kpeoplevcard")
    (version "0.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://kde/stable/kpeoplevcard/"
                                  version "/kpeoplevcard-" version ".tar.xz"))
              (sha256
               (base32
                "1hv3fq5k0pps1wdvq9r1zjnr0nxf8qc3vwsnzh9jpvdy79ddzrcd"))))
    (build-system qt-build-system)
    (arguments
     '(#:phases (modify-phases %standard-phases
                  (replace 'check-setup
                    (lambda _
                      (setenv "HOME" "/tmp"))))))
    (native-inputs
     (list extra-cmake-modules))
    (inputs
     (list kcontacts kpeople qtbase-5))
    (home-page "https://invent.kde.org/pim/kpeoplevcard")
    (synopsis "Expose vCard contacts to KPeople")
    (description
     "This plugins adds support for vCard (also known as @acronym{VCF,
Virtual Contact File}) files to the KPeople contact management library.")
    (license license:lgpl2.1+)))

(define-public kpkpass
  (package
    (name "kpkpass")
    (version "24.05.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://kde/stable/release-service/" version
                                  "/src/kpkpass-" version ".tar.xz"))
              (sha256
               (base32
                "1cqpmag3n58nzcbyb1rkkvwx9lzff1l8nawbqz2g1gqk2diny0wx"))))
    (build-system qt-build-system)
    (native-inputs (list extra-cmake-modules))
    (inputs (list karchive shared-mime-info))
    (arguments (list #:qtbase qtbase))
    (home-page "https://invent.kde.org/pim/kpkpass")
    (synopsis "Apple Wallet Pass reader")
    (description "This package provides library to deal with Apple Wallet
pass files.")
    (license license:lgpl2.0+)))

(define-public kpimcommon
  (package
    (name "kpimcommon")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/pimcommon-" version ".tar.xz"))
       (sha256
        (base32 "0k7zakx1dd39997a9a3d6qmlzdc5alw5gny0xh7bncv0fpilvgyh"))))
    (properties `((upstream-name . "pimcommon")))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules qttools))
    (inputs
     (list karchive
           akonadi
           akonadi-contacts
           akonadi-mime
           akonadi-search
           boost
           grantleetheme
           kaccounts-integration
           kcalendarcore
           kcmutils
           kcodecs
           kconfig
           kconfigwidgets
           kcontacts
           kcoreaddons
           ki18n
           kiconthemes
           kio
           kirigami ;; run-time dependency
           kitemmodels
           kitemviews
           kjobwidgets
           kldap
           kmime
           knewstuff
           kpimtextedit
           ktextwidgets
           ktexttemplate
           kwallet
           kwidgetsaddons
           kwindowsystem
           kxmlgui
           libxslt
           purpose
           qtwebengine))
    (propagated-inputs (list kimap ktextaddons libkdepim))
    (arguments
     (list #:qtbase qtbase))
    (home-page "https://invent.kde.org/pim/pimcommon")
    (synopsis "Common libraries for KDE PIM")
    (description "This package provides common libraries for KDE PIM.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public libgravatar
  (package
    (name "libgravatar")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/libgravatar-" version ".tar.xz"))
       (sha256
        (base32 "0xk6i1rndhh58p20hx6473hc29njg03qcy7ymdvflr5lgr7qavwy"))))
    (build-system qt-build-system)
    (native-inputs (list extra-cmake-modules))
    (inputs (list kconfig
                  ki18n
                  kio
                  kconfigwidgets
                  kpimcommon
                  kpimtextedit
                  ktextaddons
                  ktextwidgets
                  kwidgetsaddons
                  qtbase))
    (arguments
     (list #:qtbase qtbase
           #:tests? #f)) ;; 2/7 tests fail (due to network issues?)
    (home-page "https://invent.kde.org/pim/libgravatar")
    (synopsis "Online avatar lookup library")
    (description "This library retrieves avatar images based on a
hash from a person's email address, as well as local caching to avoid
unnecessary network operations.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public kpimtextedit
  (package
    (name "kpimtextedit")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/kpimtextedit-" version ".tar.xz"))
       (sha256
        (base32 "1m91hnjiksji60ybvmvlcgayqrcplxfdj7qxknxwayiijvqiq22a"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules qttools))
    (inputs
     (list kcodecs
           kconfigwidgets
           kcoreaddons
           ktextaddons
           ki18n
           kiconthemes
           kio
           ksyntaxhighlighting
           ktextwidgets
           kwidgetsaddons
           kxmlgui
           qtspeech
           sonnet))
    (arguments
     (list #:qtbase qtbase
           #:tests? #f)) ;; TODO - test suite hangs
    (home-page "https://api.kde.org/kdepim/kpimtextedit/html/index.html")
    (synopsis "Library providing a textedit with PIM-specific features")
    (description "This package provides a textedit with PIM-specific features.
It also provides so-called rich text builders which can convert the formatted
text in the text edit to all kinds of markup, like HTML or BBCODE.")
    (license ;; GPL for programs, LGPL for libraries, FDL for documentation
     (list license:gpl2+ license:lgpl2.0+ license:fdl1.2+))))

(define-public ksmtp
  (package
    (name "ksmtp")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/ksmtp-" version ".tar.xz"))
       (sha256
        (base32 "1v7kami1f75gin7293kk07imkdnmvf9bfn49fc6lzbb52im4nh4b"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules))
    (inputs
     (list cyrus-sasl
           kcodecs
           kconfig
           kcoreaddons
           ki18n
           kio))
    (arguments
     (list #:qtbase qtbase
           #:tests? #f ;; TODO: does not find sasl mechs
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'Use-KDE_INSTALL_TARGETS_DEFAULT_ARGS-when-installing
                 (lambda _
                   (substitute* "src/CMakeLists.txt"
                     (("^(install\\(.* )\\$\\{KF5_INSTALL_TARGETS_DEFAULT_ARGS\\}\\)"
                       _ prefix)
                      (string-append prefix "${KDE_INSTALL_TARGETS_DEFAULT_ARGS})"))))))))
    (home-page "https://invent.kde.org/pim/ksmtp")
    (synopsis "Library for sending email through an SMTP server")
    (description "This library provides an API for handling SMTP
services.  SMTP (Simple Mail Transfer Protocol) is the most prevalent Internet
standard protocols for e-mail transmission.")
    (license license:lgpl2.0+)))

(define-public ktnef
  (package
    (name "ktnef")
    (version "23.04.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/ktnef-" version ".tar.xz"))
       (sha256
        (base32 "00dkcmywjxzq5v2kp4klw50c3w74lmh16kbcwn8qd97kky3pd5ik"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules))
    (inputs
     (list kcalendarcore
           kcalutils
           kcodecs
           kconfig
           kcontacts
           kcoreaddons
           ki18n
           qtbase-5))
    (home-page "https://api.kde.org/kdepim/ktnef/html/index.html")
    (synopsis "Library for handling mail attachments using TNEF format")
    (description "Ktnef is a library for handling data in the TNEF
format (Transport Neutral Encapsulation Format, a proprietary format of e-mail
attachment used by Microsoft Outlook and Microsoft Exchange Server).  The API
permits access to the actual attachments, the message properties (TNEF/MAPI),
and allows one to view/extract message formatted text in Rich Text Format.")
    (license license:lgpl2.0+)))

(define-public libkdepim
  (package
    (name "libkdepim")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/libkdepim-" version ".tar.xz"))
       (sha256
        (base32 "1k22qjxfm8msj8ipyz2p5qq0hx9q6p3qw42cp3bnbhiaamanmlq3"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules qttools))
    (inputs
     (list akonadi
           akonadi-contacts
           akonadi-mime
           akonadi-search
           boost
           kcmutils
           kcodecs
           kcalendarcore
           kcompletion
           kconfig
           kconfigwidgets
           kcontacts
           kcoreaddons
           kdbusaddons
           ki18n
           kiconthemes
           kio
           kitemmodels
           kitemviews
           kjobwidgets
           kldap
           kmime
           kwallet
           kwidgetsaddons))
    (arguments (list #:qtbase qtbase))
    (home-page "https://invent.kde.org/pim/libkdepim")
    (synopsis "Libraries for common KDE PIM apps")
    (description "This package provided libraries for common KDE PIM apps.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public libkgapi
  (package
    (name "libkgapi")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/libkgapi-" version ".tar.xz"))
       (sha256
        (base32 "0j0rbzwcjq4wjrrk0vhkifa8ahmmrpfy039fpf3gy237k5ncj5y3"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules qttools))
    (inputs
     (list cyrus-sasl
           ki18n
           kcontacts
           kcalendarcore
           kio
           kwallet
           kwindowsystem
           qtdeclarative
           qtwebchannel
           qtwebengine))
    (arguments
     (list #:qtbase qtbase
           #:tests? #f)) ;; TODO 6/48 tests fail
    (home-page "https://invent.kde.org/pim/libkgapi")
    (synopsis "Library for accessing various Google services via their public
API")
    (description "@code{LibKGAPI} is a C++ library that implements APIs for
various Google services.")
    (license license:lgpl2.0+)))

(define-public libkleo
  (package
    (name "libkleo")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/libkleo-" version ".tar.xz"))
       (sha256
        (base32 "102yszx6smyf2vd068p6j0921fql5jlmsra3n62xam81smqlpgj0"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules kdoctools qttools))
    (inputs
     (list boost
           gpgme-1.23
           kcodecs
           kcompletion
           kconfig
           kconfigwidgets
           kcoreaddons
           kcrash
           ki18n
           kitemmodels
           kwidgetsaddons
           kwindowsystem
           kpimtextedit
           qgpgme-qt6-1.23))
    (propagated-inputs
     (list gpgme-1.23 qgpgme-qt6-1.23))
    (arguments
     (list
      #:qtbase qtbase
      #:phases
      #~(modify-phases %standard-phases
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests? ;; FIXME: These tests fail.
                (invoke "ctest" "-E"
                        "(expirycheckertest|keyresolvercoretest|\
newkeyapprovaldialogtest)")))))))
    (home-page "https://invent.kde.org/pim/libkleo")
    (synopsis "KDE PIM cryptographic library")
    (description "@code{libkleo} is a library for Kleopatra and other parts of
KDE using certificate-based crypto.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public libksieve
  (package
    (name "libksieve")
    (version "24.05.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/release-service/" version
                           "/src/libksieve-" version ".tar.xz"))
       (sha256
        (base32
	 "1zsc84ylrylby28ypdg47kmf911dmi5hi6745wvjsrxcwnpqag37"))))
    (build-system qt-build-system)
    (native-inputs
     (list extra-cmake-modules kdoctools))
    (inputs
     (list akonadi
           cyrus-sasl
           grantleetheme
           kconfigwidgets
           karchive
           ki18n
           kiconthemes
           kidentitymanagement
           kimap
           kio
           kmailtransport
           kmime
           knewstuff
           kpimcommon
           kpimtextedit
           ksyntaxhighlighting
           ktextaddons
           ktextwidgets
           kwallet
           kwindowsystem
           libkdepim
           qtdeclarative
           qtwebchannel
           qtwebengine))
    (arguments
     (list #:qtbase qtbase
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'substitute
                 (lambda _
                   ;; Disable a failing test
                   ;; sieveeditorhelphtmlwidgettest fails with `sigtrap`
                   (substitute*
                       "src/ksieveui/editor/webengine/autotests/CMakeLists.txt"
                     (("^\\s*(add_test|ecm_mark_as_test|set_tests_properties)\\W" line)
                      (string-append "# " line))))))))
    (home-page "https://invent.kde.org/pim/libksieve")
    (synopsis "KDE Sieve library")
    (description "Sieve is a language that can be used filter emails.  KSieve
is a Sieve parser and interpreter library for KDE.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))
