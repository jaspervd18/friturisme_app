import { useState } from "react";
import {
  View,
  Text,
  TextInput,
  Pressable,
  ScrollView,
  Alert,
  ActivityIndicator,
} from "react-native";
import { router } from "expo-router";
import * as WebBrowser from "expo-web-browser";
import { makeRedirectUri } from "expo-auth-session";
import Animated, {
  FadeIn,
  FadeInDown,
  FadeInUp,
} from "react-native-reanimated";
import { supabase } from "@/lib/supabase";

WebBrowser.maybeCompleteAuthSession();

const redirectUri = makeRedirectUri();

async function navigateAfterAuth(userId: string) {
  const { data } = await supabase
    .from("users")
    .select("favorite_snacks")
    .eq("id", userId)
    .single<{ favorite_snacks: string[] }>();

  if (data?.favorite_snacks && data.favorite_snacks.length > 0) {
    router.replace("/(tabs)");
  } else {
    router.replace("/(auth)/onboarding");
  }
}

export default function LoginScreen() {
  const [emailExpanded, setEmailExpanded] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  async function signInWithGoogle() {
    setLoading(true);
    try {
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: "google",
        options: {
          redirectTo: redirectUri,
          skipBrowserRedirect: true,
        },
      });

      if (error) throw error;
      if (!data.url) throw new Error("Geen OAuth URL ontvangen");

      const result = await WebBrowser.openAuthSessionAsync(
        data.url,
        redirectUri,
      );

      if (result.type === "success") {
        const url = new URL(result.url);
        const params = new URLSearchParams(
          url.hash ? url.hash.substring(1) : url.search.substring(1),
        );
        const accessToken = params.get("access_token");
        const refreshToken = params.get("refresh_token");

        if (accessToken && refreshToken) {
          const { data: sessionData, error: sessionError } =
            await supabase.auth.setSession({
              access_token: accessToken,
              refresh_token: refreshToken,
            });
          if (sessionError) throw sessionError;
          if (sessionData.user) {
            await navigateAfterAuth(sessionData.user.id);
          }
        }
      }
    } catch (err) {
      Alert.alert(
        "Er is iets misgelopen",
        "Waarschijnlijk het frituurvet. Probeer opnieuw.",
      );
    } finally {
      setLoading(false);
    }
  }

  async function signInWithApple() {
    setLoading(true);
    try {
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: "apple",
        options: {
          redirectTo: redirectUri,
          skipBrowserRedirect: true,
        },
      });

      if (error) throw error;
      if (!data.url) throw new Error("Geen OAuth URL ontvangen");

      const result = await WebBrowser.openAuthSessionAsync(
        data.url,
        redirectUri,
      );

      if (result.type === "success") {
        const url = new URL(result.url);
        const params = new URLSearchParams(
          url.hash ? url.hash.substring(1) : url.search.substring(1),
        );
        const accessToken = params.get("access_token");
        const refreshToken = params.get("refresh_token");

        if (accessToken && refreshToken) {
          const { data: sessionData, error: sessionError } =
            await supabase.auth.setSession({
              access_token: accessToken,
              refresh_token: refreshToken,
            });
          if (sessionError) throw sessionError;
          if (sessionData.user) {
            await navigateAfterAuth(sessionData.user.id);
          }
        }
      }
    } catch (err) {
      Alert.alert(
        "Er is iets misgelopen",
        "Waarschijnlijk het frituurvet. Probeer opnieuw.",
      );
    } finally {
      setLoading(false);
    }
  }

  async function signInWithEmail() {
    if (!email || !password) {
      Alert.alert("Oeps", "Vul uw e-mail en wachtwoord in.");
      return;
    }
    setLoading(true);
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      if (error) throw error;
      if (data.user) {
        await navigateAfterAuth(data.user.id);
      }
    } catch {
      Alert.alert(
        "Inloggen mislukt",
        "Controleer uw e-mail en wachtwoord.",
      );
    } finally {
      setLoading(false);
    }
  }

  async function signUpWithEmail() {
    if (!email || !password) {
      Alert.alert("Oeps", "Vul uw e-mail en wachtwoord in.");
      return;
    }
    if (password.length < 6) {
      Alert.alert("Te kort", "Uw wachtwoord moet minstens 6 tekens hebben.");
      return;
    }
    setLoading(true);
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
      });
      if (error) throw error;
      if (data.user && !data.session) {
        Alert.alert(
          "Check uw inbox",
          "We hebben een bevestigingsmail gestuurd. Klik op de link en log dan in.",
        );
      } else if (data.user && data.session) {
        await navigateAfterAuth(data.user.id);
      }
    } catch {
      Alert.alert(
        "Registratie mislukt",
        "Probeer een ander e-mailadres of wachtwoord.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <ScrollView
      className="flex-1 bg-nacht-warm"
      contentContainerStyle={{ flexGrow: 1 }}
      keyboardShouldPersistTaps="handled"
    >
      {loading && (
        <View className="absolute inset-0 z-50 items-center justify-center bg-nacht-warm/80">
          <ActivityIndicator size="large" color="#F2C744" />
          <Text className="font-outfit-medium text-mayo-creme/50 mt-3 text-sm">
            Even geduld, we bakken het klaar...
          </Text>
        </View>
      )}

      {/* Logo section */}
      <Animated.View
        entering={FadeIn.duration(600)}
        className="items-center pt-16 pb-6 px-8"
      >
        <Text className="text-5xl mb-3">🍟</Text>
        <Text
          className="font-archivo text-friet-geel text-4xl tracking-wider"
          style={{
            textShadowColor: "#E8742A",
            textShadowOffset: { width: 2, height: 2 },
            textShadowRadius: 0,
          }}
        >
          FRITURISME
        </Text>
        <Text className="font-serif-italic text-kroket-goud text-base mt-2 text-center leading-6">
          {"Ge kent uw frituur.\nMaar kent ge alle frituren?"}
        </Text>
      </Animated.View>

      {/* OAuth buttons */}
      <Animated.View
        entering={FadeInDown.delay(200).duration(500)}
        className="px-5 pt-4"
      >
        {/* Google */}
        <Pressable
          onPress={signInWithGoogle}
          disabled={loading}
          className="flex-row items-center justify-center bg-[#FFFDF5] rounded-btn py-3.5 mb-2.5"
        >
          <Text className="text-base mr-2.5">🔵</Text>
          <Text className="font-outfit-semibold text-stoofvlees-bruin text-sm">
            Verder met Google
          </Text>
        </Pressable>

        {/* Apple */}
        <Pressable
          onPress={signInWithApple}
          disabled={loading}
          className="flex-row items-center justify-center bg-white rounded-btn py-3.5 mb-2.5"
        >
          <Text className="text-base mr-2.5">🍎</Text>
          <Text className="font-outfit-semibold text-[#1a1a1a] text-sm">
            Verder met Apple
          </Text>
        </Pressable>

        {/* Divider */}
        <Pressable
          onPress={() => setEmailExpanded(!emailExpanded)}
          className="flex-row items-center py-3"
        >
          <View className="flex-1 h-px bg-mayo-creme/10" />
          <Text className="font-outfit text-mayo-creme/35 text-xs px-3">
            {emailExpanded ? "verberg e-mail" : "of met e-mail"}
          </Text>
          <View className="flex-1 h-px bg-mayo-creme/10" />
        </Pressable>

        {/* Email section */}
        {emailExpanded && (
          <Animated.View entering={FadeInUp.duration(300)}>
            <TextInput
              className="w-full bg-nacht-donker border border-friet-geel/[0.12] rounded-btn py-3.5 px-4 text-[#FFFDF5] font-outfit text-sm mb-2.5"
              placeholder="uw.email@voorbeeld.be"
              placeholderTextColor="rgba(255,248,231,0.35)"
              value={email}
              onChangeText={setEmail}
              autoCapitalize="none"
              keyboardType="email-address"
              textContentType="emailAddress"
              autoComplete="email"
            />
            <TextInput
              className="w-full bg-nacht-donker border border-friet-geel/[0.12] rounded-btn py-3.5 px-4 text-[#FFFDF5] font-outfit text-sm mb-2.5"
              placeholder="wachtwoord"
              placeholderTextColor="rgba(255,248,231,0.35)"
              value={password}
              onChangeText={setPassword}
              secureTextEntry
              textContentType="password"
              autoComplete="password"
            />

            {/* Log in button */}
            <Pressable
              onPress={signInWithEmail}
              disabled={loading}
              className="bg-friet-geel rounded-[14px] py-3.5 items-center mt-1"
              style={{
                shadowColor: "#D4952B",
                shadowOffset: { width: 0, height: 4 },
                shadowOpacity: 1,
                shadowRadius: 0,
                elevation: 4,
              }}
            >
              <Text className="font-archivo text-stoofvlees-bruin text-[15px] tracking-wider">
                INLOGGEN
              </Text>
            </Pressable>

            {/* Register link */}
            <Pressable onPress={signUpWithEmail} disabled={loading}>
              <Text className="text-center py-4 font-outfit text-mayo-creme/35 text-xs">
                Nog geen account?{" "}
                <Text className="text-friet-geel font-outfit-semibold">
                  Maak er eentje
                </Text>
              </Text>
            </Pressable>
          </Animated.View>
        )}
      </Animated.View>

      {/* Footer */}
      <View className="flex-1" />
      <Animated.Text
        entering={FadeIn.delay(400).duration(500)}
        className="font-outfit text-mayo-creme/35 text-[11px] text-center px-10 pb-10 leading-4"
      >
        Door verder te gaan accepteer je dat friet superieur is aan patat.
      </Animated.Text>
    </ScrollView>
  );
}
