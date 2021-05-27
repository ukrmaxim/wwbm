import Rails from "@rails/ujs"

import 'bootstrap/dist/js/bootstrap'
import '../stylesheets/application.scss'
import "@fortawesome/fontawesome-free/css/all"

Rails.start()

const images = require.context('../images', true)
