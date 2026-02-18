package com.example.mytodo

import android.app.Activity
import android.app.DatePickerDialog
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.EditText
import android.widget.ImageButton
import android.widget.Spinner
import android.widget.TextView
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import java.util.Calendar

class WidgetQuickAddActivity : Activity() {

    private var selectedDueMillis: Long? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_widget_quick_add)
        setFinishOnTouchOutside(true)
        window?.setLayout(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
        )
        window?.setGravity(Gravity.BOTTOM)

        val initialKind = intent.getStringExtra("kind") ?: "todo"

        val titleInput = findViewById<EditText>(R.id.quick_add_input)
        val titleView = findViewById<TextView>(R.id.quick_add_title)
        val closeButton = findViewById<ImageButton>(R.id.quick_add_close)
        val dueButton = findViewById<Button>(R.id.quick_add_due)
        val dueClearButton = findViewById<Button>(R.id.quick_add_due_clear)
        val kindSpinner = findViewById<Spinner>(R.id.quick_add_kind_spinner)
        val prioritySpinner = findViewById<Spinner>(R.id.quick_add_priority_spinner)
        val advancedButton = findViewById<Button>(R.id.quick_add_advanced)
        val saveButton = findViewById<Button>(R.id.quick_add_save)

        titleView.text =
            if (initialKind == "dayPlan") getString(R.string.quick_add_title_dayplan)
            else getString(R.string.quick_add_title)

        val kindOptions = listOf("ToDo", "Day Plan")
        val kindAdapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, kindOptions)
        kindAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        kindSpinner.adapter = kindAdapter
        kindSpinner.setSelection(if (initialKind == "dayPlan") 1 else 0)

        val priorityOptions = listOf("Low", "Medium", "High")
        val priorityAdapter =
            ArrayAdapter(this, android.R.layout.simple_spinner_item, priorityOptions)
        priorityAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        prioritySpinner.adapter = priorityAdapter
        prioritySpinner.setSelection(1)

        closeButton.setOnClickListener { finish() }
        dueButton.setOnClickListener {
            showDatePicker { millis ->
                selectedDueMillis = millis
                dueButton.text = android.text.format.DateFormat.format("yyyy-MM-dd", millis)
            }
        }
        dueClearButton.setOnClickListener {
            selectedDueMillis = null
            dueButton.text = getString(R.string.quick_add_due_none)
        }

        advancedButton.setOnClickListener {
            val selectedKind = if (kindSpinner.selectedItemPosition == 1) "dayPlan" else "todo"
            val openUri = Uri.parse("mydo://widget?action=open_add&kind=$selectedKind")
            val openIntent = Intent(this, MainActivity::class.java).apply {
                action = "es.antonborri.home_widget.action.LAUNCH"
                data = openUri
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(openIntent)
            finish()
        }

        saveButton.setOnClickListener {
            val title = titleInput.text?.toString()?.trim().orEmpty()
            if (title.isEmpty()) {
                titleInput.error = getString(R.string.quick_add_validation)
                return@setOnClickListener
            }

            val selectedKind = if (kindSpinner.selectedItemPosition == 1) "dayPlan" else "todo"
            val priority = when (prioritySpinner.selectedItemPosition) {
                0 -> "low"
                2 -> "high"
                else -> "medium"
            }

            val builder = Uri.parse("mydo://widget?action=add_quick").buildUpon()
                .appendQueryParameter("kind", selectedKind)
                .appendQueryParameter("task", title)
                .appendQueryParameter("priority", priority)
            selectedDueMillis?.let { builder.appendQueryParameter("dueMillis", it.toString()) }
            val uri = builder.build()

            val backgroundIntent =
                Intent(this, HomeWidgetBackgroundReceiver::class.java).apply {
                    action = "es.antonborri.home_widget.action.BACKGROUND"
                    data = uri
                }
            sendBroadcast(backgroundIntent)
            finish()
        }
    }

    private fun showDatePicker(onSelected: (Long) -> Unit) {
        val now = Calendar.getInstance()
        DatePickerDialog(
            this,
            { _, year, month, dayOfMonth ->
                val calendar = Calendar.getInstance().apply {
                    set(year, month, dayOfMonth, 9, 0, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                onSelected(calendar.timeInMillis)
            },
            now.get(Calendar.YEAR),
            now.get(Calendar.MONTH),
            now.get(Calendar.DAY_OF_MONTH),
        ).show()
    }
}
