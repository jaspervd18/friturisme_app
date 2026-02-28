import "../global.css";

import { DarkTheme, ThemeProvider } from "@react-navigation/native";
import { useFonts } from "expo-font";
import { Stack, router, useSegments } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import { useEffect, useState } from "react";
import { Session } from "@supabase/supabase-js";
import "react-native-reanimated";
import { supabase } from "@/lib/supabase";

export { ErrorBoundary } from "expo-router";

export const unstable_settings = {
  initialRouteName: "(auth)",
};

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded, error] = useFonts({
    ArchivoBlack: require("../assets/fonts/ArchivoBlack-Regular.ttf"),
    DMSerifText: require("../assets/fonts/DMSerifText-Regular.ttf"),
    DMSerifTextItalic: require("../assets/fonts/DMSerifText-Italic.ttf"),
    OutfitLight: require("../assets/fonts/Outfit-Light.ttf"),
    OutfitRegular: require("../assets/fonts/Outfit-Regular.ttf"),
    OutfitMedium: require("../assets/fonts/Outfit-Medium.ttf"),
    OutfitSemiBold: require("../assets/fonts/Outfit-SemiBold.ttf"),
    OutfitBold: require("../assets/fonts/Outfit-Bold.ttf"),
  });

  useEffect(() => {
    if (error) throw error;
  }, [error]);

  useEffect(() => {
    if (loaded) {
      SplashScreen.hideAsync();
    }
  }, [loaded]);

  if (!loaded) {
    return null;
  }

  return <RootLayoutNav />;
}

function RootLayoutNav() {
  const [session, setSession] = useState<Session | null>(null);
  const [isReady, setIsReady] = useState(false);
  const segments = useSegments();

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session: s } }) => {
      setSession(s);
      setIsReady(true);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, s) => {
      setSession(s);
    });

    return () => subscription.unsubscribe();
  }, []);

  useEffect(() => {
    if (!isReady) return;

    const inAuthGroup = segments[0] === "(auth)";

    if (session && inAuthGroup) {
      // Logged in but on auth screen — check onboarding then redirect
      (async () => {
        const { data } = await supabase
          .from("users")
          .select("favorite_snacks")
          .eq("id", session.user.id)
          .single<{ favorite_snacks: string[] }>();

        if (data?.favorite_snacks && data.favorite_snacks.length > 0) {
          router.replace("/(tabs)");
        } else {
          router.replace("/(auth)/onboarding");
        }
      })();
    } else if (!session && !inAuthGroup) {
      // Not logged in but on protected screen
      router.replace("/(auth)/login");
    }
  }, [session, isReady, segments]);

  return (
    <ThemeProvider value={DarkTheme}>
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="(auth)" />
        <Stack.Screen name="(tabs)" />
        <Stack.Screen name="modal" options={{ presentation: "modal" }} />
      </Stack>
    </ThemeProvider>
  );
}
