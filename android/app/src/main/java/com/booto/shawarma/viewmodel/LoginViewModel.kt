package com.booto.shawarma.viewmodel

import android.content.Context
import androidx.compose.runtime.State
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.booto.shawarma.repository.POSRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val repository: POSRepository,
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val sharedPrefs = context.getSharedPreferences("booto_pos_prefs", Context.MODE_PRIVATE)

    private val _pin = mutableStateOf("")
    val pin: State<String> = _pin

    private val _rememberMe = mutableStateOf(false)
    val rememberMe: State<Boolean> = _rememberMe

    private val _isPasswordVisible = mutableStateOf(false)
    val isPasswordVisible: State<Boolean> = _isPasswordVisible

    private val _error = mutableStateOf<String?>(null)
    val error: State<String?> = _error

    private val _isLoading = mutableStateOf(false)
    val isLoading: State<Boolean> = _isLoading

    init {
        // Read remember me preference
        _rememberMe.value = sharedPrefs.getBoolean("remember_me", false)
        if (_rememberMe.value) {
            _pin.value = sharedPrefs.getString("saved_pin", "") ?: ""
        }
    }

    fun onPinChange(newPin: String) {
        if (newPin.length <= 4 && newPin.all { it.isDigit() }) {
            _pin.value = newPin
            _error.value = null
        }
    }

    fun onRememberMeChange(value: Boolean) {
        _rememberMe.value = value
    }

    fun togglePasswordVisibility() {
        _isPasswordVisible.value = !_isPasswordVisible.value
    }

    fun login(onSuccess: () -> Unit) {
        val enteredPin = _pin.value
        if (enteredPin.length < 4) {
            _error.value = "PIN must be 4 digits"
            return
        }

        viewModelScope.launch {
            _isLoading.value = true
            val admin = repository.verifyAdminPin(enteredPin)
            _isLoading.value = false

            if (admin != null) {
                // Save preferences
                sharedPrefs.edit().apply {
                    putBoolean("remember_me", _rememberMe.value)
                    if (_rememberMe.value) {
                        putString("saved_pin", enteredPin)
                        putBoolean("is_logged_in", true)
                    } else {
                        remove("saved_pin")
                        putBoolean("is_logged_in", false)
                    }
                    apply()
                }
                onSuccess()
            } else {
                _error.value = "Wrong PIN! Access Denied."
            }
        }
    }

    fun isLoggedIn(): Boolean {
        return sharedPrefs.getBoolean("remember_me", false) && sharedPrefs.getBoolean("is_logged_in", false)
    }

    fun logout() {
        sharedPrefs.edit().apply {
            putBoolean("is_logged_in", false)
            apply()
        }
        _pin.value = ""
    }
}
