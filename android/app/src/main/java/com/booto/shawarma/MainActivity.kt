package com.booto.shawarma

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.booto.shawarma.ui.screens.*
import com.booto.shawarma.ui.theme.BooToTheme
import com.booto.shawarma.ui.theme.DarkCard
import com.booto.shawarma.ui.theme.GoldAccent
import com.booto.shawarma.ui.theme.TextMuted
import com.booto.shawarma.viewmodel.*
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            BooToTheme {
                MainAppScreen()
            }
        }
    }
}

@Composable
fun MainAppScreen() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    val showBottomBar = currentRoute != null && currentRoute != "splash" && currentRoute != "login"

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                BottomAppBar(
                    containerColor = DarkCard,
                    contentColor = Color.White,
                    modifier = Modifier.height(72.dp),
                    tonalElevation = 8.dp
                ) {
                    Row(
                        modifier = Modifier.fillMaxSize(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Dashboard
                        val isDashboard = currentRoute == "dashboard"
                        Column(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            IconButton(onClick = {
                                navController.navigate("dashboard") {
                                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }) {
                                Icon(
                                    imageVector = Icons.Default.Home,
                                    contentDescription = "Dashboard",
                                    tint = if (isDashboard) GoldAccent else TextMuted
                                )
                            }
                            Text("Dashboard", color = if (isDashboard) GoldAccent else TextMuted, fontSize = 10.sp)
                        }

                        // Orders
                        val isOrders = currentRoute == "orders"
                        Column(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            IconButton(onClick = {
                                navController.navigate("orders") {
                                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }) {
                                Icon(
                                    imageVector = Icons.Default.ShoppingCart,
                                    contentDescription = "Orders",
                                    tint = if (isOrders) GoldAccent else TextMuted
                                )
                            }
                            Text("Orders", color = if (isOrders) GoldAccent else TextMuted, fontSize = 10.sp)
                        }

                        // Center FAB for New Order
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight(),
                            contentAlignment = Alignment.Center
                        ) {
                            FloatingActionButton(
                                onClick = {
                                    navController.navigate("new_order") {
                                        popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                        launchSingleTop = true
                                        restoreState = true
                                    }
                                },
                                containerColor = GoldAccent,
                                contentColor = Color.Black,
                                shape = CircleShape,
                                modifier = Modifier.offset(y = (-16).dp)
                            ) {
                                Icon(Icons.Default.Add, contentDescription = "New Order")
                            }
                        }

                        // Sales
                        val isSales = currentRoute == "sales"
                        Column(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            IconButton(onClick = {
                                navController.navigate("sales") {
                                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }) {
                                Icon(
                                    imageVector = Icons.Default.Info,
                                    contentDescription = "Sales",
                                    tint = if (isSales) GoldAccent else TextMuted
                                )
                            }
                            Text("Sales", color = if (isSales) GoldAccent else TextMuted, fontSize = 10.sp)
                        }

                        // Menu
                        val isMenu = currentRoute == "menu"
                        Column(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            IconButton(onClick = {
                                navController.navigate("menu") {
                                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }) {
                                Icon(
                                    imageVector = Icons.Default.List,
                                    contentDescription = "Menu",
                                    tint = if (isMenu) GoldAccent else TextMuted
                                )
                            }
                            Text("Menu", color = if (isMenu) GoldAccent else TextMuted, fontSize = 10.sp)
                        }
                    }
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = "splash",
            modifier = Modifier.padding(innerPadding)
        ) {
            composable("splash") {
                val loginViewModel: LoginViewModel = hiltViewModel()
                SplashScreen(
                    viewModel = loginViewModel,
                    onNavigateNext = { isLoggedIn ->
                        if (isLoggedIn) {
                            navController.navigate("dashboard") {
                                popUpTo("splash") { inclusive = true }
                            }
                        } else {
                            navController.navigate("login") {
                                popUpTo("splash") { inclusive = true }
                            }
                        }
                    }
                )
            }
            composable("login") {
                val loginViewModel: LoginViewModel = hiltViewModel()
                LoginScreen(
                    viewModel = loginViewModel,
                    onLoginSuccess = {
                        navController.navigate("dashboard") {
                            popUpTo("login") { inclusive = true }
                        }
                    }
                )
            }
            composable("dashboard") {
                val dashboardViewModel: DashboardViewModel = hiltViewModel()
                DashboardScreen(
                    viewModel = dashboardViewModel,
                    onNavigateToNewOrder = { navController.navigate("new_order") },
                    onNavigateToOrders = { navController.navigate("orders") }
                )
            }
            composable("new_order") {
                val newOrderViewModel: NewOrderViewModel = hiltViewModel()
                NewOrderScreen(
                    viewModel = newOrderViewModel,
                    onNavigateToOrders = { navController.navigate("orders") }
                )
            }
            composable("orders") {
                val ordersViewModel: OrdersViewModel = hiltViewModel()
                OrdersScreen(viewModel = ordersViewModel)
            }
            composable("sales") {
                val salesViewModel: SalesViewModel = hiltViewModel()
                SalesScreen(viewModel = salesViewModel)
            }
            composable("menu") {
                val menuViewModel: MenuViewModel = hiltViewModel()
                MenuScreen(viewModel = menuViewModel)
            }
        }
    }
}
