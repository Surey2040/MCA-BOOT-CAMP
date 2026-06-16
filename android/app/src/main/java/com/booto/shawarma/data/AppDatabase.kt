package com.booto.shawarma.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@Database(entities = [CustomerEntity::class, MenuItemEntity::class, ExtraEntity::class, OrderEntity::class, OrderItemEntity::class, AdminEntity::class], version = 1, exportSchema = false)
abstract class AppDatabase : RoomDatabase() {
    abstract fun appDao(): AppDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context, scope: CoroutineScope): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "booto_shawarma.db"
                )
                .addCallback(AppDatabaseCallback(scope))
                .build()
                INSTANCE = instance
                instance
            }
        }
    }

    private class AppDatabaseCallback(
        private val scope: CoroutineScope
    ) : RoomDatabase.Callback() {
        override fun onCreate(db: SupportSQLiteDatabase) {
            super.onCreate(db)
            INSTANCE?.let { database ->
                scope.launch(Dispatchers.IO) {
                    populateDatabase(database.appDao())
                }
            }
        }

        suspend fun populateDatabase(dao: AppDao) {
            // Seed Admin
            dao.insertAdmin(AdminEntity(name = "Admin", pin = "1234"))

            // Seed Menu Items
            val menuItems = listOf(
                // Shawarma
                MenuItemEntity(category = "Shawarma", name = "Classic Shawarma", price = 120.0),
                MenuItemEntity(category = "Shawarma", name = "Spicy Shawarma", price = 130.0),
                MenuItemEntity(category = "Shawarma", name = "Mexican Shawarma", price = 140.0),
                MenuItemEntity(category = "Shawarma", name = "Tandoori Shawarma", price = 130.0),

                // Lays Shawarma
                MenuItemEntity(category = "Lays Shawarma", name = "Lays Classic", price = 130.0),
                MenuItemEntity(category = "Lays Shawarma", name = "Lays Spanish", price = 140.0),
                MenuItemEntity(category = "Lays Shawarma", name = "Lays Cream & Onion", price = 140.0),
                MenuItemEntity(category = "Lays Shawarma", name = "Lays Chili Limón", price = 140.0),
                MenuItemEntity(category = "Lays Shawarma", name = "Lays BBQ", price = 140.0),

                // Mug Shawarma
                MenuItemEntity(category = "Mug Shawarma", name = "Mug Classic", price = 150.0),
                MenuItemEntity(category = "Mug Shawarma", name = "Mug Spicy", price = 160.0),
                MenuItemEntity(category = "Mug Shawarma", name = "Mug Peri Peri", price = 160.0),
                MenuItemEntity(category = "Mug Shawarma", name = "Mug BBQ", price = 160.0),
                MenuItemEntity(category = "Mug Shawarma", name = "Mug Schezwan", price = 160.0),
                MenuItemEntity(category = "Mug Shawarma", name = "Mug Mexican", price = 150.0)
            )
            dao.insertMenuItems(menuItems)

            // Seed Extras
            val extras = listOf(
                ExtraEntity(name = "Cheese", price = 20.0),
                ExtraEntity(name = "Mayo", price = 10.0),
                ExtraEntity(name = "Peri Peri", price = 10.0)
            )
            dao.insertExtras(extras)
        }
    }
}
