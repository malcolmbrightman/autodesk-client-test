<template>
  <div class="app-container">
    <header class="app-header">
      <h1>Autodesk API Tester</h1>
    </header>

    <main class="app-main">
      <div v-if="!accessToken" class="auth-form card">
        <h2>Authenticate</h2>
        <input
          type="text"
          placeholder="Client ID"
          v-model="clientId"
        />
        <input
          type="password"
          placeholder="Client Secret"
          v-model="clientSecret"
        />
        <button @click="handleAuth" class="button-primary">Authenticate</button>
        <div v-if="authError" class="error-message">{{ authError }}</div>
      </div>

      <div v-else class="content-area">
        <div v-if="hubs.length > 0" class="hub-selector card">
          <label for="hubSelect">Select a Hub:</label>
          <select id="hubSelect" v-model="selectedHub">
            <option value="">-- Select a Hub --</option>
            <option v-for="hub in hubs" :key="hub.id" :value="hub.id">
              {{ hub.attributes.name }} ({{ hub.id }})
            </option>
          </select>
          <!-- Use ProjectDashboard component -->
          <ProjectDashboard
            v-if="selectedHub"
            :access-token="accessToken"
            :hub-id="selectedHub"
            class="project-dashboard-component"
          />
        </div>
        <div v-else class="card">
          <p>Loading hubs or no hubs found...</p>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue';
import axios from 'axios';
import ProjectDashboard from './ProjectDashboard.vue';

const clientId = ref('');
const clientSecret = ref('');
const accessToken = ref(null);
const hubs = ref([]);
const selectedHub = ref('');
const authError = ref(null);

const handleAuth = async () => {
  try {
    const response = await axios.post('http://localhost:3001/auth', {
      clientId: clientId.value,
      clientSecret: clientSecret.value
    });
    accessToken.value = response.data.access_token;
    authError.value = null;
    console.log('Authentication status: Successful');
  } catch (error) {
    console.error('Authentication failed', error);
    authError.value = error.message || 'Authentication failed';
    accessToken.value = null;
    console.log('Authentication status: Failed');
  }
};

const fetchHubs = async () => {
  if (accessToken.value) {
    try {
      const response = await axios.get('http://localhost:3001/hubs', {
        headers: {
          Authorization: `Bearer ${accessToken.value}`
        }
      });
      hubs.value = response.data;
      console.log('Hubs fetched successfully');
    } catch (error) {
      console.error('Failed to fetch hubs', error);
    }
  } else {
    hubs.value = [];
    selectedHub.value = '';
  }
};

watch(accessToken, fetchHubs, { immediate: true });

</script>

<style>
/* Global styles (can affect child components if not scoped carefully) */
:root {
  --primary-color: #007bff;
  --primary-color-dark: #0056b3;
  --secondary-color: #6c757d;
  --light-gray: #f8f9fa;
  --medium-gray: #dee2e6;
  --dark-gray: #343a40;
  --text-color: #212529;
  --error-color: #dc3545;
  --success-color: #28a745;
  --border-radius: 0.25rem;
  --box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
  --input-padding: 0.5rem 0.75rem;
  --font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
}

body {
  margin: 0;
  font-family: var(--font-family);
  background-color: var(--light-gray);
  color: var(--text-color);
  line-height: 1.5;
}

/* App container and layout */
.app-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 1rem;
}

.app-header {
  background-color: var(--dark-gray);
  color: white;
  padding: 1rem 1.5rem;
  border-radius: var(--border-radius);
  margin-bottom: 1.5rem;
  box-shadow: var(--box-shadow);
}

.app-header h1 {
  margin: 0;
  font-size: 1.75rem;
  text-align: center;
}

.app-main {
  display: flex;
  flex-direction: column;
  align-items: center; /* Center content like auth form */
}

/* Card styling */
.card {
  background-color: white;
  border-radius: var(--border-radius);
  padding: 1.5rem;
  box-shadow: var(--box-shadow);
  border: 1px solid var(--medium-gray);
  width: 100%;
  max-width: 600px; /* Limit width for forms/selectors */
  margin-bottom: 1.5rem;
}

.card h2 {
  margin-top: 0;
  margin-bottom: 1rem;
  color: var(--dark-gray);
  text-align: center;
}

/* Form elements */
.auth-form, .hub-selector {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

label {
 display: block;
 margin-bottom: 0.25rem;
 font-weight: 500;
}

input[type="text"],
input[type="password"],
select {
  padding: var(--input-padding);
  border-radius: var(--border-radius);
  border: 1px solid var(--medium-gray);
  font-size: 1rem;
  width: 100%;
  box-sizing: border-box;
  transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;
}

input[type="text"]:focus,
input[type="password"]:focus,
select:focus {
  border-color: var(--primary-color);
  outline: 0;
  box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
}

select {
  appearance: none; /* Modern look for select */
  background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3e%3cpath fill='none' stroke='%23343a40' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M2 5l6 6 6-6'/%3e%3c/svg%3e");
  background-repeat: no-repeat;
  background-position: right 0.75rem center;
  background-size: 16px 12px;
}

/* Buttons */
.button-primary {
  padding: 0.6rem 1rem;
  background-color: var(--primary-color);
  color: white;
  border: none;
  border-radius: var(--border-radius);
  cursor: pointer;
  font-size: 1rem;
  font-weight: 500;
  transition: background-color 0.15s ease-in-out;
}

.button-primary:hover {
  background-color: var(--primary-color-dark);
}

/* Error message */
.error-message {
  color: var(--error-color);
  margin-top: 0.5rem;
  font-size: 0.9em;
  text-align: center;
}

/* Content area after auth */
.content-area {
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.project-dashboard-component {
  margin-top: 1.5rem; /* Add space above the dashboard */
}

</style>